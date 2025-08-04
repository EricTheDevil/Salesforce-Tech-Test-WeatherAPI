@IsTest
private class WeatherSnapshotBatchTest {
    private class MultiCityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('Berlin')) {
                res.setStatusCode(200);
                res.setBody('{"current":{"temp_c":20,"last_updated_epoch":1691000000,"condition":{"text":"Sunny","icon":"//icon"}}}');
            } else {
                res.setStatusCode(500);
                res.setBody('error');
            }
            return res;
        }
    }

    @IsTest static void testBatchCreatesSnapshots() {
        List<Contact> cs = new List<Contact>{
            new Contact(LastName = 'A', MailingCity = 'Berlin'),
            new Contact(LastName = 'B', MailingCity = 'Paris')
        };
        insert cs;
        Test.setMock(HttpCalloutMock.class, new MultiCityMock());
        Test.startTest();
        Database.executeBatch(new WeatherSnapshotBatch(), 2);
        Test.stopTest();
        Map<Id, Weather_Snapshot__c> snaps = new Map<Id, Weather_Snapshot__c>([
            SELECT Contact__c, Provider_Response__c
            FROM Weather_Snapshot__c
            WHERE Contact__c IN :cs
        ]);
        System.assertEquals(2, snaps.size());
        System.assertEquals(200, snaps.get(cs[0].Id).Provider_Response__c);
        System.assertEquals(500, snaps.get(cs[1].Id).Provider_Response__c);
    }

    @IsTest static void testBatchSkipsBlankCity() {
        Contact c = new Contact(LastName = 'C', MailingCity = '');
        insert c;
        Test.startTest();
        Database.executeBatch(new WeatherSnapshotBatch(), 2);
        Test.stopTest();
        Integer cnt = [SELECT COUNT() FROM Weather_Snapshot__c WHERE Contact__c = :c.Id];
        System.assertEquals(0, cnt);
    }
}
