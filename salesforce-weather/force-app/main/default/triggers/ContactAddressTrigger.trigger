trigger ContactAddressTrigger on Contact (after insert, after update) {
    ContactAddressTriggerHandler.run(Trigger.new, Trigger.oldMap, Trigger.isInsert);
}
