/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : HHA_AuditTriggerHandler.
* @Why   : Handles all the customization involved on Health_Hazard_Assessment__c object.
* @When  : 10-JUNE-2019.
* @Where : Health_Hazard_Assessment__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    10-JUNE-2019           Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class HHA_AuditTriggerHandler {

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : Events from TriggerHandler before delete.
    * @Return       : N/A.
    * @Params       : List<Health_Hazard_Assessment__c>.
    */
    public static void beforeDelete(List<Health_Hazard_Assessment__c> lstHHAOld){
    	//stop RMF to be deleted if parent / grand parent is in closed status.
    	for(Health_Hazard_Assessment__c objHHA : lstHHAOld){
            if(objHHA.Parent_WF_status__c == true){
                objHHA.addError(System.label.RMF_cannot_be_deleted);
            }
    	}
	}
}