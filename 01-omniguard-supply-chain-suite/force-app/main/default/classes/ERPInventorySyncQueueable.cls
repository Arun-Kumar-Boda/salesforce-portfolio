public with sharing class ERPInventorySyncQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> shipmentIds;
    private Integer retryCount;

    public ERPInventorySyncQueueable(Set<Id> shipmentIds) {
        this(shipmentIds, 0);
    }

    public ERPInventorySyncQueueable(Set<Id> shipmentIds, Integer retryCount) {
        this.shipmentIds = shipmentIds;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        TransactionFinalizer finalizer = new TransactionFinalizer(this.shipmentIds, this.retryCount);
        System.attachFinalizer(finalizer);

        List<Shipment__c> shipments = [
            SELECT Id, Name, Vendor__c, Vendor__r.Primary_Backup_Vendor__c, Status__c, ERP_Sync_Status__c
            FROM Shipment__c
            WHERE Id IN :this.shipmentIds
            WITH USER_MODE
        ];

        if (shipments.isEmpty()) return;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ERP_Inventory_API/v2/reallocations');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(shipments));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            for (Shipment__c s : shipments) {
                if (s.Vendor__r.Primary_Backup_Vendor__c != null) {
                    s.Vendor__c = s.Vendor__r.Primary_Backup_Vendor__c;
                }
                s.Status__c = 'Rerouted';
                s.ERP_Sync_Status__c = 'Synced';
            }
            Database.update(shipments, AccessLevel.USER_MODE);
        } else {
            throw new CalloutException('ERP Sync failed with HTTP ' + res.getStatusCode());
        }
    }
}
