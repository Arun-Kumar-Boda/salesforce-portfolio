public with sharing class VendorRiskAgentAction {

    public class RiskEvaluationRequest {
        @InvocableVariable(label='Vendor Account ID' required=true)
        public Id vendorId;

        @InvocableVariable(label='Severity Threshold' required=true)
        public Decimal threshold;
    }

    public class RiskEvaluationResult {
        @InvocableVariable(label='Mitigation Status')
        public String status;

        @InvocableVariable(label='Impacted Shipments Count')
        public Integer impactedShipments;

        @InvocableVariable(label='AI Grounding Summary')
        public String groundingContext;
    }

    @InvocableMethod(
        label='Evaluate Vendor Risk & Auto-Mitigate'
        description='Analyzes delayed shipments for a vendor, publishes Platform Events for high risk, and queues ERP inventory reallocation.'
        category='Supply Chain Autonomous Actions'
    )
    public static List<RiskEvaluationResult> evaluateAndMitigate(List<RiskEvaluationRequest> requests) {
        List<RiskEvaluationResult> results = new List<RiskEvaluationResult>();
        Set<Id> vendorIds = new Set<Id>();

        for (RiskEvaluationRequest req : requests) {
            vendorIds.add(req.vendorId);
        }

        Map<Id, Account> vendorMap = new Map<Id, Account>([
            SELECT Id, Name, Risk_Score__c, Primary_Backup_Vendor__c,
                   (SELECT Id, Name, Status__c, Estimated_Value__c FROM Shipments__r WHERE Status__c = 'Delayed')
            FROM Account
            WHERE Id IN :vendorIds
            WITH USER_MODE
        ]);

        List<Vendor_Risk_Alert__e> eventsToPublish = new List<Vendor_Risk_Alert__e>();
        Set<Id> shipmentsToReroute = new Set<Id>();

        for (RiskEvaluationRequest req : requests) {
            RiskEvaluationResult res = new RiskEvaluationResult();
            Account vendor = vendorMap.get(req.vendorId);

            if (vendor == null) {
                res.status = 'ERROR: Vendor not found or inaccessible.';
                res.impactedShipments = 0;
                results.add(res);
                continue;
            }

            List<Shipment__c> delayedShipments = vendor.Shipments__r;
            res.impactedShipments = delayedShipments.size();

            if (vendor.Risk_Score__c >= req.threshold && !delayedShipments.isEmpty()) {
                for (Shipment__c ship : delayedShipments) {
                    shipmentsToReroute.add(ship.Id);
                }

                eventsToPublish.add(new Vendor_Risk_Alert__e(
                    Vendor_Id__c = vendor.Id,
                    Vendor_Name__c = vendor.Name,
                    Risk_Score__c = vendor.Risk_Score__c,
                    Action_Taken__c = 'Autonomous Reroute Initiated'
                ));

                res.status = 'MITIGATION_TRIGGERED';
            } else {
                res.status = 'MONITORING_ONLY';
            }

            res.groundingContext = JSON.serialize(new Map<String, Object>{
                'vendorName' => vendor.Name,
                'riskScore' => vendor.Risk_Score__c,
                'delayedCount' => res.impactedShipments,
                'mitigationStatus' => res.status
            });
            results.add(res);
        }

        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
        }

        if (!shipmentsToReroute.isEmpty() && !System.isQueueable()) {
            System.enqueueJob(new ERPInventorySyncQueueable(shipmentsToReroute));
        }

        return results;
    }
}
