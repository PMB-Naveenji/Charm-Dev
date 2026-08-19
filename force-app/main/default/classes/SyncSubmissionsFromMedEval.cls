/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SyncSubmissionsFromMedEval.
* @Why   : global class to auto populate fields in submissions (EMDR and MDI) from medical evaluation.
* @When  : 23-MAR-2017.
* @Where : From SyncSubmissionsFromMedEval.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-06-2020             Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-06-2020             Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman               03-Dec-2020            Charm Upgrade                     Changed the field value from CMPL123CME__G4_Date_received_by_MFG__c to CMPL123CME__G3_Date_received_by_Mfg__c.
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Neeraj                 14-June-2021           FRS-1470-07                       Moved code to queable class because of limit and added MIR updation code 
* ---------------------------------------------------------------------------------------------------------------------------------------
*
*/

global class SyncSubmissionsFromMedEval {
    /*
    * @Method       : submissionFieldUpdateMethod.
    * @Description  : Method to perform field updates in the EMDR and MDI child records of the medical evaluation.
    * @Invoke       : Events submissionFieldUpdateMethod.
    * @Return       : N/A.
    * @Params       : Id medDevId.
    */
    webservice static void submissionFieldUpdateMethod(Id medDevId){
        //Variable Declaration
        System.enqueueJob(new SyncSubmissionsFromMedEvalQueueable(medDevId));
    }
}