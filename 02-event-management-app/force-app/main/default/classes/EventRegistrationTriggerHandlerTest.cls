@IsTest
private class EventRegistrationTriggerHandlerTest {
    private class BadgeServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testBulkInsertAndAsyncCallout() {
        Test.setMock(HttpCalloutMock.class, new BadgeServiceMock());
        List<Event_Registration__c> testRegs = new List<Event_Registration__c>();
        for (Integer i = 0; i < 200; i++) {
            testRegs.add(new Event_Registration__c(Status__c = 'Confirmed'));
        }
        Test.startTest();
        insert testRegs;
        Test.stopTest();

        List<Event_Registration__c> insertedRegs = [SELECT Id, Status__c FROM Event_Registration__c];
        Assert.areEqual(200, insertedRegs.size(), 'All 200 records should be inserted.');
    }
}
