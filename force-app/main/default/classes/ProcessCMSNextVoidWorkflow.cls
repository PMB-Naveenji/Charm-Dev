/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ProcessCMSNextVoidWorkflow.
* @Why   : DemoteToServiceWorkflowProcess class is invoked from DemoteToService process builder.
* @When  : 23-MAR-2017
* @Where : From ProcessCMSNextVoidWorkflow
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017		    Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public class ProcessCMSNextVoidWorkflow {

    /*
    * @Method       : ProcessVoidWorkflow.
    * @Description  : Class to Handle invocable method when CMSNext Status is changed.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Complaint__c> records.
    */
    @InvocableMethod
    public static void ProcessVoidWorkflow(List<CMPL123CME__Complaint__c> records){
        ComplaintTriggerHandler.moveChildrenOpenToClose(records,false);
    }
}