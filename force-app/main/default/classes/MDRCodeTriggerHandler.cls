/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
 * @What  : MDRCodeTriggerHandler.
 * @Why   : Public class to manage all the custom coding invoked from MDRCodeTrigger.
 * @When  : 08-JAN-2019.
 * @Where : From MDRCodeTriggerHandler.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                    Modification ID             Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                 08-JAN-2019             Work ID / Case ID           Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                 22-MAY-2020             #123/CHARM-2729             Added return of updated ticket ids
 *                                                                           into updateEMDRH6EvaluationCodes.
 *                                                                           Created updateEMDRLastModifiedDate method.
 *                                                                           Added isAfterUpdate method.
 *                                                                           Added updateEMDRLastModifiedDate calls.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                 19-AUG-2020             Code Audit                  Adjusted class/method headers.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                 06-NOV-2020             HC #100.11/CHARM-3518       Added record lock if parent eMDR is pending.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          23-FEB-2023             CHaRM R3.0, TWD Upgrade     TWD package now handles the HL7 Validations
 * which include verifying that H6 codes are set on an eMDR. CHaRM's custom code is no longer needed, so
 * updateEMDRH6EvaluationCodes has been commented out.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

public class MDRCodeTriggerHandler {

    /**
     * @Method       : isAfterInsert.
     * @Description  : Handles logic on after insert event.
     * @Invoke       : From MDRCodeTrigger.
     * @Return       : Boolean.
     * @Params       : N/A.
     */
    public static void isAfterInsert(){
        // Defect #123/CHARM-2729: Added assignment of updateEMDRH6EvaluationCodes's result to emdrsUpdated set
        Set<Id> emdrsUpdated = new Set<Id>();//updateEMDRH6EvaluationCodes(Trigger.New);
        // Defect #123/CHARM-2729: Added method call
        updateEMDRLastModifiedDate(emdrsUpdated, Trigger.New);
    }

    /**
     * @Method       : isAfterUpdate.
     * @Description  : Handles logic on after update event.
     * @Invoke       : From MDRCodeTrigger.
     * @Return       : Boolean.
     * @Params       : N/A.
     */
    //Defect #123/CHARM-2729: added isAfterUpdate method
    public static void isAfterUpdate(){
        updateEMDRLastModifiedDate(new Set<Id>(), (List<CMPL123CME__MDR_Code__c>)Trigger.New);
    }

    /**
     * @Method       : isAfterDelete.
     * @Description  : Handles logic on after delete event.
     * @Invoke       : From MDRCodeTrigger.
     * @Return       : Boolean.
     * @Params       : N/A.
     */
    public static void isAfterDelete(){
        // updateEMDRH6EvaluationCodes(Trigger.Old);
    }

    /**
     * @Method       : updateEMDRH6EvaluationCodes.
     * @Description  : W-000249 - 1059 / (eMDR) Require at least one code for device and patient should be added for an initial eMDR.
     * @Invoke       : From MDRCodeTrigger.
     * @Return       : Set<Id> emdrsToUpdate.
     * @Params       : List<CMPL123CME__MDR_Code__c> lstMDRCodes.
     * @Revision     : 24-JAN-2023 by Larry for TWD Complaints Winter '23.
     * Commented all code because the managed package now handles this.
     * Retained as comments because we may need to re-enable this custom solution
     * if the managed package's solution conflicts with business processes
     */
    // Defect #123/CHARM-2729: changed void return result to  Set<Id>
    // private static Set<Id> updateEMDRH6EvaluationCodes(List<CMPL123CME__MDR_Code__c> lstMDRCodes){
    //     Set<Id> setEMDRIds = New Set<Id>();
    //     Set<Id> emdrsToUpdate = new Set<Id>();  // Defect #123/CHARM-2729: added to collect updated emdrs
    //     List<CMPL123CME__EMDR__c> lstEMDRToUpdate = new List<CMPL123CME__EMDR__c>();
    //     //Get all the MDRCodes
    //     for(CMPL123CME__MDR_Code__c objMDRCode : lstMDRCodes){
    //         if(objMDRCode.CMPL123CME__EMDR__c != null){
    //             setEMDRIds.add(objMDRCode.CMPL123CME__EMDR__c);
    //         }
    //     }

    //     if(setEMDRIds.size() > 0){
    //         Boolean isChanged = false;
    //         // HC #100.11/CHARM-3518: Added record lock if parent eMDR is pending
    //         for(CMPL123CME__EMDR__c objEMDR : [SELECT Id, CMPL123CME__CMPL123_WF_Status__c, H6_Evaluation_Codes_Required__c,(SELECT Name FROM CMPL123CME__MDR_Codes__r LIMIT 1) FROM CMPL123CME__EMDR__c WHERE Id IN: setEMDRIds]){
    //             if (objEMDR.CMPL123CME__CMPL123_WF_Status__c == 'Pending Follow Up Creation' 
    //                     || objEMDR.CMPL123CME__CMPL123_WF_Status__c == 'Pending Closure') {
    //                 lstMDRCodes.get(0).addError(System.label.Record_Locked);
    //             }
    //             for(CMPL123CME__MDR_Code__c objMDRCode : objEMDR.CMPL123CME__MDR_Codes__r){
    //                 if(objEMDR.H6_Evaluation_Codes_Required__c != objMDRCode.Name){
    //                     objEMDR.H6_Evaluation_Codes_Required__c = objMDRCode.Name;
    //                     objEMDR.Last_Modified_Date_Time__c = DateTime.now();
    //                     isChanged = true;
    //                 }
    //             }

    //             if(objEMDR.CMPL123CME__MDR_Codes__r.size() == 0 && objEMDR.H6_Evaluation_Codes_Required__c != ''){
    //                 objEMDR.H6_Evaluation_Codes_Required__c = '';
    //                 objEMDR.Last_Modified_Date_Time__c = DateTime.now();
    //                 isChanged = true;
    //             }

    //             if(isChanged){
    //                 lstEMDRToUpdate.add(objEMDR);
    //                 emdrsToUpdate.add(objEMDR.Id);
    //             }
    //         }

    //         if(lstEMDRToUpdate.size() > 0){
    //             update lstEMDRToUpdate;
    //         }
    //     }
    //     return emdrsToUpdate;
    // }

    /**
     * @Method       : updateEMDRLastModifiedDate.
     * @Description  : To update parent record "LastModifiedDate" field based on child records.
     * @Invoke       : Events from Trigger after insert/update.
     * @Return       : N/A.
     * @Params       : Set<Id> updatedTicketIds.
     */
    // Defect #123/CHARM-2729: added method to update parent EMDRs if they weren't updated in current transaction
    public static void updateEMDRLastModifiedDate(Set<Id> updatedEMDRIds, List<CMPL123CME__MDR_Code__c> newMDRCodes){
        if (!EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild) {
            Set<Id> emdrRecordIdSet = new Set<Id>();
            for(CMPL123CME__MDR_Code__c mdrCode : newMDRCodes){
                Id emdrId = mdrCode.CMPL123CME__EMDR__c;
                if (emdrId != null && !updatedEMDRIds.contains(emdrId)){
                    emdrRecordIdSet.add(emdrId);
                }
            }
            EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild = true;
            UpdateParentUtility.updateparent_trend(emdrRecordIdSet);
            EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild = false;
        }
    }

}