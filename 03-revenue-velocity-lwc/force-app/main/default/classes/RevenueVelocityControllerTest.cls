@IsTest
private class RevenueVelocityControllerTest {
    @IsTest
    static void testPipelineQueryAndStagePromotion() {
        Account acc = new Account(Name = 'Enterprise Corp');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Enterprise Cloud Deal',
            AccountId = acc.Id,
            Amount = 120000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Test.startTest();
        List<Opportunity> pipeline = RevenueVelocityController.getHighVelocityPipeline('Negotiation/Review');
        RevenueVelocityController.promoteOpportunityStage(opp.Id, 'Closed Won');
        Test.stopTest();

        Assert.areEqual(1, pipeline.size(), 'Should return 1 high-velocity opportunity.');
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Closed Won', updatedOpp.StageName, 'Stage should be promoted to Closed Won.');
    }
}
