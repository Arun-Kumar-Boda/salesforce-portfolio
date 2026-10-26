public with sharing class TransactionFinalizer implements System.Finalizer {
    private Set<Id> shipmentIds;
    private Integer retryCount;
    private static final Integer MAX_RETRIES = 2;

    public TransactionFinalizer(Set<Id> shipmentIds, Integer retryCount) {
        this.shipmentIds = shipmentIds;
        this.retryCount = retryCount;
    }

    public void execute(FinalizerContext context) {
        if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            Exception ex = context.getException();
            Async_Error_Log__c logRec = new Async_Error_Log__c(
                Job_Id__c = String.valueOf(context.getAsyncApexJobId()),
                Error_Message__c = ex.getMessage(),
                Stack_Trace__c = ex.getStackTraceString()
            );
            Database.insert(logRec, AccessLevel.SYSTEM_MODE);

            if (this.retryCount < MAX_RETRIES) {
                System.enqueueJob(new ERPInventorySyncQueueable(this.shipmentIds, this.retryCount + 1));
            }
        }
    }
}
