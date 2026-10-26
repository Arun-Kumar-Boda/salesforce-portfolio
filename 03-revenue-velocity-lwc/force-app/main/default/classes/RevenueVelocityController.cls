public with sharing class RevenueVelocityController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getHighVelocityPipeline(String stageFilter) {
        String safeStage = String.isBlank(stageFilter) ? 'Negotiation/Review' : stageFilter;
        return [
            SELECT Id, Name, Account.Name, Amount, StageName, CloseDate, Probability
            FROM Opportunity
            WHERE StageName = :safeStage AND Amount >= 25000
            WITH USER_MODE
            ORDER BY Amount DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void promoteOpportunityStage(Id opportunityId, String nextStage) {
        Opportunity opp = new Opportunity(Id = opportunityId, StageName = nextStage);
        Database.update(opp, AccessLevel.USER_MODE);
    }
}
