/**
 * Handles Contact address change events and enqueues weather refresh jobs.
 */
public with sharing class ContactAddressTriggerHandler {
    /**
     * Enqueues refresh jobs when contact addresses change.
     */
    public static void run(List<Contact> newList, Map<Id, Contact> oldMap, Boolean isInsert) {
        Set<Id> ids = new Set<Id>();
        for (Contact c : newList) {
            Contact oldC = isInsert ? null : oldMap.get(c.Id);
            if (isInsert || hasAddressChanged(c, oldC)) {
                ids.add(c.Id);
            }
        }
        if (!ids.isEmpty()) {
            System.enqueueJob(new WeatherSnapshotJob(ids));
        }
    }

    /**
     * Determines if a contact's address changed.
     */
    private static Boolean hasAddressChanged(Contact c, Contact oldC) {
        if (oldC == null) return true;
        return c.MailingStreet != oldC.MailingStreet ||
               c.MailingCity != oldC.MailingCity ||
               c.MailingState != oldC.MailingState ||
               c.MailingPostalCode != oldC.MailingPostalCode ||
               c.MailingCountry != oldC.MailingCountry;
    }
}