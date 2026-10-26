@IsTest
private class OmniGuardSuiteTest {
    private class ERPMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"REALLOCATED","erpReference":"ERP-99412"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Account backupVendor = new Account(Name = 'Apex Global Logistics (Backup)', Risk_Score__c = 15);
        insert backupVendor;

        Account primaryVendor = new Account(
            Name = 'Pacific Freight Corp',
            Risk_Score__c = 88,
            Primary_Backup_Vendor__c = backupVendor.Id
        );
        insert primaryVendor;

        List<Shipment__c> shipments = new List<Shipment__c>();
        for (Integer i = 0; i < 50; i++) {
            shipments.add(new Shipment__c(
                Vendor__c = primaryVendor.Id,
                Status__c = 'Delayed',
                Estimated_Value__c = 12500
            ));
        }
        insert shipments;
    }

    @IsTest
    static void testAgentforceMitigationAndERPQueueable() {
        Test.setMock(HttpCalloutMock.class, new ERPMockSuccess());
        Account primaryVendor = [SELECT Id FROM Account WHERE Name = 'Pacific Freight Corp' LIMIT 1];
        Account backupVendor = [SELECT Id FROM Account WHERE Name = 'Apex Global Logistics (Backup)' LIMIT 1];

        Test.startTest();
        String status = SupplyChainDashboardController.triggerManualMitigation(primaryVendor.Id, 75);
        Test.stopTest();

        Assert.areEqual('MITIGATION_TRIGGERED', status, 'Expected autonomous mitigation to trigger.');
        List<Shipment__c> updatedShipments = [
            SELECT Id, Status__c, ERP_Sync_Status__c
            FROM Shipment__c
            WHERE Vendor__c = :backupVendor.Id
        ];
        Assert.areEqual(50, updatedShipments.size(), 'All 50 delayed shipments should be reallocated.');
    }
}
