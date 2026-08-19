/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RMF_AuditTriggerHandler.
* @Why   : Handles all the customization involved on RMF__c object.
* @When  : 10-JUN-2019.
* @Where : From RMF__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    10-JUN-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class RMF_AuditTriggerHandler {
    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : Events from TriggerHandler before delete.
    * @Return       : N/A.
    * @Params       : List<RMF> oldRMFList.
    */
    public static void beforeDelete(List<RMF__c> oldRMFList){
    //stop RMF to be deleted if parent / grand parent is in closed status.
        for(RMF__c rmfObj : oldRMFList){
            if(rmfObj.Parent_WF_status__c == true){
                rmfObj.addError(System.label.RMF_cannot_be_deleted);
            }
        }
    }
}