/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : DemoteToServiceWorkflowProcess.
* @Why   : DemoteToServiceWorkflowProcess class is invoked from DemoteToService process builder.
* @When  : 16-OCT-2018.
* @Where : Class to Handle invocable method when Demotional Rational is changed.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 16-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 19-AUG-2020            Code Audit                      Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class DemoteToServiceWorkflowProcess {

    /*
    * @Method       : processWorkflow.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : Events from TriggerHandler before insert.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Complaint__c> records.
    *                 Param 1 : complaint records,
    *                 Param 2 : Boolean true-Because ticket creating in CHARM.
    */
    @InvocableMethod
    public static void processWorkflow(List<CMPL123CME__Complaint__c> records){
        ComplaintTriggerHandler.moveChildrenOpenToClose(records,true);
    }
}