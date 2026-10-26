public with sharing class ExternalBadgeServiceQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> registrationIds;

    public ExternalBadgeServiceQueueable(Set<Id> registrationIds) {
        this.registrationIds = registrationIds;
    }

    public void execute(QueueableContext context) {
        List<Event_Registration__c> regsToProcess = [
            SELECT Id, Name, Status__c, CreatedDate
            FROM Event_Registration__c
            WHERE Id IN :this.registrationIds
            WITH USER_MODE
        ];
        if (regsToProcess.isEmpty()) return;

        Map<String, Object> payload = new Map<String, Object>{
            'source' => 'Salesforce Enterprise',
            'registrations' => regsToProcess
        };

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Badge_Printing_API/v1/badges');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse response = http.send(request);
    }
}
