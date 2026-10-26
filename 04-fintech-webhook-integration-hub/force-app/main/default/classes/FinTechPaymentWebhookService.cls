@RestResource(urlMapping='/v1/payments/webhook/*')
global with sharing class FinTechPaymentWebhookService {
    public class PaymentPayload {
        public String externalTransactionId;
        public Id accountId;
        public Decimal amount;
        public String status;
    }

    @HttpPost
    global static void handlePaymentNotification() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            PaymentPayload payload = (PaymentPayload) JSON.deserialize(
                req.requestBody.toString(), PaymentPayload.class
            );
            Account acc = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :payload.accountId WITH USER_MODE LIMIT 1];
            acc.AnnualRevenue = (acc.AnnualRevenue == null ? 0 : acc.AnnualRevenue) + payload.amount;
            Database.update(acc, AccessLevel.USER_MODE);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status":"PROCESSED"}');
        } catch (Exception ex) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error":"' + ex.getMessage() + '"}');
        }
    }
}
