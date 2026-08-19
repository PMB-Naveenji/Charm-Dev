/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : UpdateParentUtility
* @Why   : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection
* @When  : 02-Apr-2019
* @Where : From Trend_Item_Product_AuditTrigger, Trend_Item_Trend_Bucket_AuditTrigger, Trend_Item_Issue_Code_AuditTrigger ,
* CMPL123CME_EMDR_AuditTrigger, Product_Lot_AuditTrigger, CMPL123CME_MEDDEV_AuditTrigger, Regulatory_Task_AuditTrigger, Medical_Evaluation_Task_AuditTrigger Triggers
 *  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID             Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    02-Apr-2019            Work ID / Case ID           Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    27-May-2020            Defect #123/CHARM-2729      Added isTicketUpdated flag.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-June-2020           Code Audit                  Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    09-June-2020           Defect #123/CHARM-2729      Added isTicketUpdated flag.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                  Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    23-June-2020           Defect #123.1/CHARM-2878    Added isTicketUpdated flag.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    13-JUL-2020            Defect #123.2/CHARM-3007    Adjusted logic related to isTriggeredFromChild flag.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    22-DEC-2020            Upgrade issue #41           Added isDemotedOrPromoted flag logic.
* ---------------------------------------------------------------------------------------------------------------------------------------
**/

public class UpdateParentUtility {
    public static boolean flag = true;
    
    //Added to stop complaint trigger when only Last modified Date Updated  DEF#1117 - 05JUN2019
    public static boolean ticketTriggerPreventFlag = false;
    // Defect #123/CHARM-2729: added below flags to prevent multiple updates of the parent in the same transaction
    public static boolean isTicketUpdated = false;
    public static boolean isMedEvalUpdated = false;
    public static boolean isMedEvalLastModifDateUpdating = false;
    public static boolean isMedDevUpdated = false;
    public static boolean isEuMirUpdated = false;
    public static boolean isEuMirLastModifDateUpdating = false;
    public static boolean isMedDevLastModifDateUpdating = false;
    public static boolean isInvestigationUpdated = false;
    public static boolean isInvestigationLastModifDateUpdating = false;
    public static boolean isTrendItemUpdated = false;
    public static boolean isTrendItemLastModifDateUpdating = false;
    /* Defect #123.1/CHARM-2878: added updateTicketCustomLastModifDate, isCustomLastModifDateUpdated 
    and isTriggeredFromChild flags*/
    public static boolean updateTicketCustomLastModifDate = false;
    public static boolean isCustomLastModifDateUpdated = false;
    public static boolean isTriggeredFromChild = false;

    public static void updateparent(Set<Id> Ids) {
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if (isTicketUpdated || ComplaintTriggerHandler.isTicketInserting || ADDDemoteToServiceHandler.isDemotedOrPromoted) {
            return;
        }
        List<sObject> sObjectsToUpdate = new List<sObject>();          
        for(Id idToUpdate : Ids){
            sObject obj = idToUpdate.getSobjectType().newsObject(idToUpdate);
            obj.put('Id', idToUpdate);
            //Blind update to trigger update standard lastmodifieddate on Ticket
            //Commented - Not needed for TODS Blind Update -TP
            //obj.put('Last_Modified_Date_Time__c', DateTime.now());
            sObjectsToUpdate.add(obj);            
        }
        try{
            /* Defect #123.1/CHARM-2878: set isTriggeredFromChild to true in order to allow ticket custom
            Last_Modified_Date_Time__c field update if updateTicketCustomLastModifDate == false and update was made
            on ticket itself*/
            isTriggeredFromChild = true;
            // Uncommented by TP for TODS Integration issue DEF#1117
            update sObjectsToUpdate;  // MR - 01APR19 - Commented for DEF#650 Testing 
            // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
            isTicketUpdated = true;
            // Defect #123.2/CHARM-3007: assign false to isTriggeredFromChild when an after update is completed.
            isTriggeredFromChild = false;
        } catch(Exception e) {
            system.debug('Error: ' + e);
        }
     
    }
    
    
    /**
    * @Method       : updateparent_trend
    * @Invoke       : Events from TriggerHandler after insert / update
    * @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection
    * @Return       : N/A
    * @Params       : Parent record Ids
    **/    
    public static void updateparent_trend(Set<Id> Ids) {
        List<sObject> sObjectsToUpdate = new List<sObject>();          
        for(Id idToUpdate : Ids){
            // Defect #123/CHARM-2729: skip loop logic if id is null
            if (idToUpdate == null) {
                break;
            }
            sObject obj = idToUpdate.getSobjectType().newsObject(idToUpdate);
            obj.put('Id', idToUpdate);
            // #123.1/CHARM-2878: remove custom Last_Modified_Date_Time__c field update for untracked objects
            //obj.put('Last_Modified_Date_Time__c', DateTime.now());
            sObjectsToUpdate.add(obj);            
        }
        try{
            update sObjectsToUpdate;
        } catch(Exception e) {
            system.debug('Error: ' + e);
        }
    }
    
    /**
    * @Method       : updateTicketLastModifiedDate
    * @Invoke       : Events from Trigger after insert/update
    * @Description  : To update parent record based on child records
    * @Return       : N/A
    * @Params       : Set<Id> updatedTicketIds
    **/ 
    // Defect #123.1/CHARM-2878: added method to update parent tickets if they weren't updated in current transaction
    public static void updateTicketLastModifiedDate(List<SObject> records, Set<Id> updatedTicketIds,
        String ticketFieldAPI, Boolean isCustomLastModifDateNeeded){
        Set<Id> setComplaintIdToUpdate = new Set<Id>();
        if(!isTicketUpdated && !ComplaintTriggerHandler.isTicketInserting){
            for (SObject objRecord : records) {
                Id ticketId = (Id)objRecord.get(ticketFieldAPI);
                if (ticketId != null && !updatedTicketIds.contains(ticketId)) {
                    setComplaintIdToUpdate.add(ticketId);              
                }
            }
        }
        // Defect #123.2//CHARM-3007: update custom Last Modified Date if it wasn't already updated
        if (isCustomLastModifDateNeeded && !isCustomLastModifDateUpdated) {
            for (SObject objRecord : records) {
                Id ticketId = (Id)objRecord.get(ticketFieldAPI);
                if (ticketId != null) {
                    setComplaintIdToUpdate.add(ticketId);              
                }
            }
        }
        if(setComplaintIdToUpdate.size() > 0){
            ticketTriggerPreventFlag = true;
            // Def #123.1/CHARM-2878: update parent ticket custom Last Modified Date/Time field
            updateTicketCustomLastModifDate = isCustomLastModifDateNeeded;
            updateparent(setComplaintIdToUpdate);
            // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution 
            ticketTriggerPreventFlag = false;
        }       
    }
}