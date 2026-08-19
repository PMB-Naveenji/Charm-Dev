/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDNoteTriggerHandler.
* @Why   : Handles all the customization involved on Note object, defect #1156, 1166.
* @When  : 12-JUN-2017.
* @Where : From NoteTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                 Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 12-JUN-2017          Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 11-AUG-2020          Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDNoteTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From NoteTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        noteModificationCheck((List<Note>) Trigger.new);
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From NoteTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
        noteModificationCheck((List<Note>) Trigger.new);
    }

    /*
    * @Method       : NoteModificationCheck.
    * @Description  : To prevent insertion/updating on submitted/closed eMDRs.
    * @Invoke       : From ADDNoteTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Note> notes.
    */
    public void noteModificationCheck(List<Note> notes) {
        String emdrKeyPefix = CMPL123CME__EMDR__c.sObjectType.getDescribe().getKeyPrefix();
        Set<Id> emdrIdSet = new Set<Id>();

        for (Note noteRecord : notes) {
            if (String.valueOf(noteRecord.ParentId).substring(0,3) == emdrKeyPefix) {
                emdrIdSet.add(noteRecord.ParentId);
            }
        }

        if (emdrIdSet.size() > 0) {
            Set<String> workflowStatusSet = new Set<String>{
                'Submitted to TIBCO',
                'Pending ACK 1',
                'Pending ACK 2',
                'Pending ACK 3',
                'Pending Closure',
                'Closed-Done',
                'Closed-Voided',
                'Pending Follow Up Creation'
            };

        	Map<Id, CMPL123CME__EMDR__c> queriedEMDRMap = new Map<Id,CMPL123CME__EMDR__c>([
                SELECT Id, CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__EMDR__c WHERE Id IN :emdrIdSet
            ]);

            for (Note noteRecord : notes) {
                if (String.valueOf(noteRecord.ParentId).substring(0,3) == emdrKeyPefix
                        && null != queriedEMDRMap.get(noteRecord.ParentId)
                        && null != queriedEMDRMap.get(noteRecord.ParentId).CMPL123CME__CMPL123_WF_Status__c
                        && workflowStatusSet.contains(queriedEMDRMap.get(noteRecord.ParentId).CMPL123CME__CMPL123_WF_Status__c)) {
                    noteRecord.addError(System.Label.Cannot_Modify_Note_on_EMDR);
                }
            }
        }
    }
}