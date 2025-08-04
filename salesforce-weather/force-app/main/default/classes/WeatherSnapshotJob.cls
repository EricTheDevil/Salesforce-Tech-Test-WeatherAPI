/**
 * Queueable job to refresh weather snapshots for contacts.
 */
public with sharing class WeatherSnapshotJob implements Queueable, Database.AllowsCallouts {

    private Set<Id> contactIds;

    private static final Integer STATUS_OK = 200;
    private static final Integer SECONDS_PER_MINUTE = 60;
    private static final Datetime UNIX_EPOCH = Datetime.newInstanceGmt(1970, 1, 1, 0, 0, 0);

    /**
     * Creates a job to refresh snapshots for the given contacts.
     */
    public WeatherSnapshotJob(Set<Id> contactIds) {
        this.contactIds = (contactIds == null) ? new Set<Id>() : new Set<Id>(contactIds);
    }

    /**
     * Runs the weather refresh for queued contacts.
     */
    public void execute(QueueableContext qc) {
        if (contactIds.isEmpty()) return;

        List<Contact> contacts = [
            SELECT Id, MailingCity
            FROM Contact
            WHERE Id IN :contactIds AND MailingCity != null
            WITH SECURITY_ENFORCED
        ];
        if (contacts.isEmpty()) return;

        Map<String, List<Id>> cityToContacts = new Map<String, List<Id>>();
        for (Contact c : contacts) {
            if (String.isBlank(c.MailingCity)) continue;
            if (!cityToContacts.containsKey(c.MailingCity)) {
                cityToContacts.put(c.MailingCity, new List<Id>());
            }
            cityToContacts.get(c.MailingCity).add(c.Id);
        }
        if (cityToContacts.isEmpty()) return;

        List<WeatherApiInvoker.Request> reqs = new List<WeatherApiInvoker.Request>();
        for (String city : cityToContacts.keySet()) {
            WeatherApiInvoker.Request r = new WeatherApiInvoker.Request();
            r.city = city;
            reqs.add(r);
        }

        List<WeatherApiInvoker.Response> resps = WeatherApiInvoker.invoke(reqs);
        Map<String, WeatherApiInvoker.Response> byCity = new Map<String, WeatherApiInvoker.Response>();
        for (Integer i=0; i<reqs.size(); i++) {
            byCity.put(reqs[i].city, resps[i]);
        }

        List<Weather_Snapshot__c> upserts = new List<Weather_Snapshot__c>();
        for (String city : cityToContacts.keySet()) {
            WeatherApiInvoker.Response r = byCity.get(city);
            for (Id cId : cityToContacts.get(city)) {
                if (r == null) continue;
                Weather_Snapshot__c snap = new Weather_Snapshot__c();
                snap.Contact__c = cId;
                snap.Provider_Response__c = r.statusCode;
                if (r.statusCode == STATUS_OK && r.lastUpdatedEpoch != null) {
                    Long minuteBucket = r.lastUpdatedEpoch / SECONDS_PER_MINUTE;
                    String upsertKey = 'WeatherAPI:' + String.valueOf(cId) + ':' + String.valueOf(minuteBucket);
                    Integer epochSeconds = Integer.valueOf(String.valueOf(r.lastUpdatedEpoch));
                    Datetime capturedAt = UNIX_EPOCH.addSeconds(epochSeconds);
                    snap.Temperature_c__c = r.tempC;
                    snap.Condition__c = r.conditionText;
                    snap.Icon_URL__c = r.iconUrl;
                    snap.Captured_At__c = capturedAt;
                    snap.Upsert_Key__c = upsertKey;
                } else {
                    snap.Upsert_Key__c = 'WeatherAPI:' + String.valueOf(cId) + ':' + Datetime.now().getTime();
                    System.debug('Weather API error for Contact ' + cId + ': ' + r.rawJson);
                }
                upserts.add(snap);
            }
        }

        if (!upserts.isEmpty()) {
            if (!Schema.sObjectType.Weather_Snapshot__c.isCreateable()) {
                throw new DmlException('No create access to Weather_Snapshot__c');
            }
            upserts = (List<Weather_Snapshot__c>) Security.stripInaccessible(AccessType.CREATABLE, upserts).getRecords();
            upsert upserts Weather_Snapshot__c.Upsert_Key__c;
        }
    }
}