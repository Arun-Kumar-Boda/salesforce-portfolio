trigger EventRegistrationTrigger on Event_Registration__c (before insert, before update, after insert, after update) {
    EventRegistrationTriggerHandler handler = new EventRegistrationTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) handler.beforeInsert(Trigger.new);
        else if (Trigger.isUpdate) handler.beforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) handler.afterInsert(Trigger.new, Trigger.oldMap);
        else if (Trigger.isUpdate) handler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
