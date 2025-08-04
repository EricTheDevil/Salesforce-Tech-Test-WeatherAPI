@IsTest
private class WeatherSnapshotServiceTest {
    @IsTest static void testRefreshForContact_Success() {
        Contact c = new Contact(LastName = 'V', MailingCity = 'Madrid');
        insert c;

        String body = '{"current":{"temp_c":18,"last_updated_epoch":1691000000,"condition":{"text":"Clear","icon":"//icon"}}}';
        Test.setMock(HttpCalloutMock.class, new WeatherApiMock(200, body));

        Test.startTest();
        WeatherSnapshotService.refreshForContact(c.Id);
        Test.stopTest();

        Integer cnt = [SELECT COUNT() FROM Weather_Snapshot__c WHERE Contact__c = :c.Id];
        System.assertEquals(1, cnt);
    }
}