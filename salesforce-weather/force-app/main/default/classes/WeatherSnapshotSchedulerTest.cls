@IsTest
private class WeatherSnapshotSchedulerTest {
    @IsTest static void testExecuteRunsBatch() {
        Contact c = new Contact(LastName = 'S', MailingCity = 'London');
        insert c;
        String body = '{"current":{"temp_c":11,"last_updated_epoch":1691000000,"condition":{"text":"Cloudy","icon":"//icon"}}}';
        Test.setMock(HttpCalloutMock.class, new WeatherApiMock(200, body));
        Test.startTest();
        new WeatherSnapshotScheduler().execute(null);
        Test.stopTest();
        Integer cnt = [SELECT COUNT() FROM Weather_Snapshot__c WHERE Contact__c = :c.Id];
        System.assertEquals(1, cnt);
    }

    @IsTest static void testScheduleHourly() {
        Test.startTest();
        String jobId = WeatherSnapshotScheduler.scheduleHourly();
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}