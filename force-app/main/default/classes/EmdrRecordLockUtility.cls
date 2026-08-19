/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EmdrRecordLockUtility.
* @Why   : This class is used to validate record update on "Submitted to TIBCO".
* @When  : 01-JAN-2019.
* @Where : From EmdrRecordLockUtility class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                  Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    01-JAN-2019           Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-JUL-2020           Code Audit                 Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    03-NOV-2020           HC #100/CHARM-3518         Removed unused validateRecordUpdateOnPendingClosure method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class EmdrRecordLockUtility {

    static String currentUserProfileId;
    static String profileName ;
   public Static boolean executeOnce = true;
    public Static boolean updateStatusexecuteOnce = true;

    static{
        currentUserProfileId = userinfo.getProfileId();
        profileName  = [SELECT Name FROM Profile WHERE Id =:currentUserProfileId].Name;
    }

    /*
    * @Method       : validateRecordUpdateOnSubmittedToTibco.
    * @Description  : Gets the new emdrs and old emdrs, and validates update functionality for particular profile.
    * @Invoke       : From CMPL123CME_EMDR_AuditTrigger on before update event.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__EMDR__c> newEmdrList, Map<Id,CMPL123CME__EMDR__c> oldEmdrMap.
    */
    public static void validateRecordUpdateOnSubmittedToTibco(List<CMPL123CME__EMDR__c> newEmdrList, Map<Id,CMPL123CME__EMDR__c> oldEmdrMap){

        for(CMPL123CME__EMDR__c objEmdr : newEmdrList){
            If(objEmdr.CMPL123CME__CMPL123_WF_Status__c == 'Submitted to TIBCO' && objEmdr.CMPL123CME__CMPL123_WF_Status__c == oldEmdrMap.get(objEmdr.Id).CMPL123CME__CMPL123_WF_Status__c && profileName != 'ASPEN Integration' && profileName != 'System Administrator' ){
                objEmdr.addError(System.Label.Record_is_locked_on_Submitted_to_TIBCO);
            }
        }
    }
}