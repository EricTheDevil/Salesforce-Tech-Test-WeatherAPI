@IsTest
private class WeatherSnapshotJobTest {
    @IsTest static void testJobCreatesSnapshot() {
        Contact c = new Contact(LastName='Test', MailingCity='London');
        insert c;
        String body = '{"current":{"temp_c":12,"last_updated_epoch":1691000000,"condition":{"text":"Sunny","icon":"//icon"}}}';
        Test.setMock(HttpCalloutMock.class, new WeatherApiMock(200, body));
        Test.startTest();
        System.enqueueJob(new WeatherSnapshotJob(new Set<Id>{ c.Id }));
        Test.stopTest();
        Weather_Snapshot__c snap = [SELECT Contact__c FROM Weather_Snapshot__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(c.Id, snap.Contact__c);
    }
}