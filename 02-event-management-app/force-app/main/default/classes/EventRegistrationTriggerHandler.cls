public with sharing class EventRegistrationTriggerHandler {
    public void beforeInsert(List<Event_Registration__c> newRegistrations) {
        for (Event_Registration__c reg : newRegistrations) {
            if (String.isBlank(reg.Status__c)) reg.Status__c = 'Pending';
        }
    }

    public void beforeUpdate(List<Event_Registration__c> newRegistrations, Map<Id, Event_Registration__c> oldMap) {
        for (Event_Registration__c reg : newRegistrations) {
            Event_Registration__c oldReg = oldMap.get(reg.Id);
            if (oldReg.Status__c == 'Confirmed' && reg.Status__c == 'Pending') {
                reg.Status__c.addError('Cannot revert a confirmed registration back to Pending status.');
            }
        }
    }

    public void afterInsert(List<Event_Registration__c> newRegistrations, Map<Id, Event_Registration__c> oldMap) {
        dispatchBadgePrintJobs(newRegistrations, null);
    }

    public void afterUpdate(List<Event_Registration__c> newRegistrations, Map<Id, Event_Registration__c> oldMap) {
        dispatchBadgePrintJobs(newRegistrations, oldMap);
    }

    private void dispatchBadgePrintJobs(List<Event_Registration__c> newRegistrations, Map<Id, Event_Registration__c> oldMap) {
        Set<Id> confirmedRegistrationIds = new Set<Id>();
        for (Event_Registration__c reg : newRegistrations) {
            Boolean isNewlyConfirmed = (oldMap == null && reg.Status__c == 'Confirmed');
            Boolean isUpdatedToConfirmed = (oldMap != null && oldMap.get(reg.Id).Status__c != 'Confirmed' && reg.Status__c == 'Confirmed');
            if (isNewlyConfirmed || isUpdatedToConfirmed) {
                confirmedRegistrationIds.add(reg.Id);
            }
        }
        if (!confirmedRegistrationIds.isEmpty() && !System.isQueueable() && !System.isFuture()) {
            System.enqueueJob(new ExternalBadgeServiceQueueable(confirmedRegistrationIds));
        }
    }
}
