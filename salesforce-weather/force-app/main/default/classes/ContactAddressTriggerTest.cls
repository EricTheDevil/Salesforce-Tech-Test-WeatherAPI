@IsTest
private class ContactAddressTriggerTest {
    @IsTest static void testTriggerUpdates() {
        Contact c = new Contact(LastName='T', MailingCity='Berlin');
        insert c;
        String body = '{"current":{"temp_c":15,"last_updated_epoch":1691000000,"condition":{"text":"Rain","icon":"//icon"}}}';
        Test.setMock(HttpCalloutMock.class, new WeatherApiMock(200, body));
        Test.startTest();
        c.MailingCity = 'Munich';
        update c;
        Test.stopTest();
        Weather_Snapshot__c snap = [SELECT Contact__c FROM Weather_Snapshot__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(c.Id, snap.Contact__c);
    }

    @IsTest static void testNoSnapshotWhenAddressUnchanged() {
        Contact c = new Contact(LastName = 'T2', MailingCity = 'Rome');
        insert c;

        Test.startTest();
        c.FirstName = 'Change';
        update c;
        Test.stopTest();

        Integer cnt = [SELECT COUNT() FROM Weather_Snapshot__c WHERE Contact__c = :c.Id];
        System.assertEquals(0, cnt);
    }
}