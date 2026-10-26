public with sharing class SupplyChainDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getHighRiskVendors() {
        return [
            SELECT Id, Name, Risk_Score__c, Primary_Backup_Vendor__r.Name,
                   (SELECT Id, Name, Status__c, Estimated_Value__c FROM Shipments__r WHERE Status__c IN ('Delayed', 'Rerouted'))
            FROM Account
            WHERE Risk_Score__c != null AND Risk_Score__c >= 50
            WITH USER_MODE
            ORDER BY Risk_Score__c DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static String triggerManualMitigation(Id vendorId, Decimal threshold) {
        VendorRiskAgentAction.RiskEvaluationRequest req = new VendorRiskAgentAction.RiskEvaluationRequest();
        req.vendorId = vendorId;
        req.threshold = threshold;
        List<VendorRiskAgentAction.RiskEvaluationResult> results =
            VendorRiskAgentAction.evaluateAndMitigate(new List<VendorRiskAgentAction.RiskEvaluationRequest>{ req });
        return results[0].status;
    }
}
