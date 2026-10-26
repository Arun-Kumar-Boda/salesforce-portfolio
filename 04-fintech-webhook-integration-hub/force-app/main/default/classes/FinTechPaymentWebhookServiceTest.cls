@IsTest
private class FinTechPaymentWebhookServiceTest {
    @IsTest
    static void testInboundPaymentWebhook() {
        Account acc = new Account(Name = 'Global FinTech Client', AnnualRevenue = 100000);
        insert acc;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/payments/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"externalTransactionId":"TX-9001","accountId":"' + acc.Id + '","amount":50000,"status":"CLEARED"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        FinTechPaymentWebhookService.handlePaymentNotification();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'Webhook should return HTTP 200.');
        Account updatedAcc = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(150000, updatedAcc.AnnualRevenue, 'AnnualRevenue should increase by 50,000.');
    }
}
