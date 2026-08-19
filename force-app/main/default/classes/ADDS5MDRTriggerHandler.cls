/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS5MDRTriggerHandler.
* @Why   : Handles all the customization involved on Meaningful Data Request object.
* @When  : 23-MAR-2017.
* @Where : From ADDMDRequestTriggerHandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017			   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 13-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS5MDRTriggerHandler{

    private static Boolean isUpdated = false;
    /*
    * @Method       : fieldUpdates.
    * @Description  : To populate fields automatically with the appropriate values.
    * @Invoke       : From ADDMDRequestTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void fieldUpdates(){
        List<Meaningful_Data_Request__c> lstMeaningfulDataRequestsToUpdate = New List<Meaningful_Data_Request__c>();
        List<Meaningful_Data_Request__c> newMDRs = (List<Meaningful_Data_Request__c>)Trigger.New;
        for(Meaningful_Data_Request__c MDR : newMDRs){
            if(Trigger.isBefore){
                MDR.Requestor_Name__c = Trigger.isInsert && MDR.Requestor_Name__c == null ?
                    UserInfo.getUserID() : MDR.Requestor_Name__c;
                // 27MAR19 - DEF#535 Fix
                //MDR.Request_Status__c = MDR.Answer_No_Answer_Rationale__c == null ?
                //  'Opened' : MDR.Request_Status__c;
            }

            if(Trigger.isUpdate && Trigger.isBefore && String.isBlank(MDR.External_ID__c)){
                MDR.External_ID__c = MDR.Id;
            }

            if(Trigger.isInsert && Trigger.isAfter && String.isBlank(MDR.External_ID__c)){
                lstMeaningfulDataRequestsToUpdate.add(New Meaningful_Data_Request__c(Id = MDR.Id, External_ID__c = MDR.Id));
            }
        }

        if(lstMeaningfulDataRequestsToUpdate.size() > 0){
            isUpdated = true;
            Update lstMeaningfulDataRequestsToUpdate;
        }

    }

    /*
    * @Method       : afterEventHandler
    * @Description  : To handle after insert/update event logic.
    * @Invoke       : From ADDMDRequestTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterEventHandler(){
        if(!isUpdated){
            List< Meaningful_Data_Request__c > newMDRs = (List< Meaningful_Data_Request__c >)Trigger.New;
            Map<Id, Meaningful_Data_Request__c > oldMDRMap = (Map<Id, Meaningful_Data_Request__c >)Trigger.oldMap;

            Set<String> complaintIds = new Set<String>();
            /*used to auto-promote event to complete status when all child are closed.
				W-001268
			*/
            if(Trigger.isUpdate){
                for(Meaningful_Data_Request__c MDRRecord : newMDRs){
                    if(MDRRecord.Ticket__c != null && MDRRecord.Request_Status__c == 'Completed' && oldMDRMap != null
                       && MDRRecord.Request_Status__c != oldMDRMap.get(MDRRecord.Id).Request_Status__c){
                           complaintIds.add(MDRRecord.Ticket__c);
                       }
                }
                if(complaintIds.size() > 0){
                    CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(complaintIds);
                }
            }
        }
    }
}