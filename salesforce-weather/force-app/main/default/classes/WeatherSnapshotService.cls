/**
 * Service layer for requesting weather refreshes for a contact.
 */
public with sharing class WeatherSnapshotService {

    /**
     * Enqueues a refresh job for the given contact.
     */
    @AuraEnabled
    public static void refreshForContact(Id contactId) {
        if (contactId == null) {
            return;        
        }
        System.enqueueJob(new WeatherSnapshotJob(new Set<Id>{ contactId }));
    }
}