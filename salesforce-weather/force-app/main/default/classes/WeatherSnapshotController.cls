/**
 * Exposes weather snapshot data to LWC clients with FLS-enforced queries.
 */
public with sharing class WeatherSnapshotController {

    public class SnapshotDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String condition;
        @AuraEnabled public Decimal temperatureC;
        @AuraEnabled public String iconUrl;
        @AuraEnabled public Datetime capturedAt;
        @AuraEnabled public Integer providerResponse;
        @AuraEnabled public String  city;
    }

    /**
     * Returns the latest snapshot for a contact.
     */
    @AuraEnabled(cacheable=true)
    public static SnapshotDTO getLatestForContact(Id contactId) {
        if (contactId == null) {
            throw new AuraHandledException('contactId is required.');
        }

        List<Weather_Snapshot__c> rows = [
            SELECT Id, Contact__c, Contact__r.MailingCity, Condition__c, Temperature_c__c,
                   Icon_URL__c, Captured_At__c, Provider_Response__c
            FROM   Weather_Snapshot__c
            WHERE  Contact__c = :contactId
            WITH   SECURITY_ENFORCED              
            ORDER  BY Captured_At__c DESC, CreatedDate DESC
            LIMIT  1
        ];

        if (rows.isEmpty()) return null;

        Weather_Snapshot__c s = rows[0];
        SnapshotDTO dto     = new SnapshotDTO();
        dto.id              = s.Id;
        dto.contactId       = s.Contact__c;
        dto.condition       = s.Condition__c;
        dto.temperatureC    = s.Temperature_c__c;
        dto.iconUrl         = s.Icon_URL__c;
        dto.capturedAt      = s.Captured_At__c;
        dto.city            = s.Contact__r != null ? s.Contact__r.MailingCity : null;
        dto.providerResponse= (s.Provider_Response__c == null)
                              ? null
                              : Integer.valueOf(s.Provider_Response__c);
        return dto;
    }
}