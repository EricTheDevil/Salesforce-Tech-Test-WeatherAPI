@IsTest
private class WeatherSnapshotControllerTest {
    @IsTest static void testGetLatest() {
        Contact c = new Contact(LastName='Test', MailingCity='Paris');
        insert c;

        Weather_Snapshot__c snap = new Weather_Snapshot__c(
            Contact__c        = c.Id,
            Temperature_c__c  = 5,
            Condition__c      = 'Cloudy',
            Icon_URL__c       = 'https://x',
            Captured_At__c    = System.now(),
            Provider_Response__c = 200
        );
        insert snap;

        Test.startTest();
        WeatherSnapshotController.SnapshotDTO dto =
            WeatherSnapshotController.getLatestForContact(c.Id);
        Test.stopTest();

        System.assertEquals(5, dto.temperatureC);
    }
}