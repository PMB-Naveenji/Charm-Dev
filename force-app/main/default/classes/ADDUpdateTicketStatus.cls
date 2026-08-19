/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDUpdateTicketStatus.
* @Why   : Updates Product Evaluation/Investigation status (Code Optimized as part of W-000063).
* @When  : 06-APR-2017.
* @Where : From "Update Prod Eval Status On Ticket" Process Builder Flow, ADDInvestigationHandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				06-APR-2017			   Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 18-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDUpdateTicketStatus {

    // Only once Run Check
    public static boolean boolIsExcuted = false;

    /*
    * @Method       : updateTicketStatus.
    * @Description  : Invoked From "Update Prod Eval Status On Ticket ProcessBuilder" (Optimized W-000063).
    * @Invoke		: To update Product Evaluation/Investigation records status.
    * @Return       : N/A.
    * @Params       : List<CMPL123CME__Investigation__c> records.
    */
    @InvocableMethod
    public static void updateTicketStatus(List<CMPL123CME__Investigation__c> records){
        // MR - Added for SOQL and CPU Time Limit Exception Fix
        if(ComplaintTriggerHandler.systemProdEval) { return; }
        TicketUtil.addTrace('ADDUpdateTicketStatus.updateTicketStatus for ' + records[0].CMPL123CME__Complaint__c);
        List<Integer> lstStatus = New List<Integer>();
        CMPL123CME__Investigation__c objInvestigation = records[0];
        //Fixed - W-000063 - Re-Order the priority STR_In_Process_Investigation 2 to 3 and STR_In_Process_Evaluation 3 to 2
        Map<String, Integer> mapStatus = New Map<String, Integer> {
            AspenConstants.STR_Assess => 1,
                AspenConstants.STR_In_Process_Evaluation => 2,
                AspenConstants.STR_In_Process_Investigation => 3,
                AspenConstants.STR_Conclude => 4,
                AspenConstants.STR_PE_Review => 5,
                AspenConstants.STR_Closed_Done => 6
                };
                    lstStatus.clear();

        if(!boolIsExcuted && objInvestigation.CMPL123CME__Complaint__c != null) {
            boolIsExcuted = true;
            //prevent Blind DML
            String strCurrentComplaintInvestigationStatus = '';

            for(Ticket_Product_Evaluation_Investigation__c objInvestigationTicket
                : [SELECT Id, Investigation_Evaluation__r.CMPL123CME__Complaint__c,Ticket__r.Investigation_Status__c,
                   Investigation_Evaluation__r.CMPL123_WF_Status__c FROM Ticket_Product_Evaluation_Investigation__c
                   WHERE Ticket__c =: objInvestigation.CMPL123CME__Complaint__c AND Type__c =: AspenConstants.STR_Source]) {
                       strCurrentComplaintInvestigationStatus = objInvestigationTicket.Ticket__r.Investigation_Status__c;
                       if(mapStatus.get(objInvestigationTicket.Investigation_Evaluation__r.CMPL123_WF_Status__c) != null) {
                           lstStatus.add(mapStatus.get(objInvestigationTicket.Investigation_Evaluation__r.CMPL123_WF_Status__c));
                       }
                   }
            String strStatus;
            lstStatus.sort();

            if(lstStatus.size() > 0) {
                if(lstStatus[0] == 1) {
                    strStatus = AspenConstants.STR_Assess;
                } else if(lstStatus[0] == 2) {
                    strStatus = AspenConstants.STR_In_Process_Evaluation;
                } else if(lstStatus[0] == 3) {
                    strStatus = AspenConstants.STR_In_Process_Investigation;
                } else if(lstStatus[0] == 4) {
                    strStatus = AspenConstants.STR_Conclude;
                } else if(lstStatus[0] == 5) {
                    strStatus = AspenConstants.STR_PE_Review;
                } else if(lstStatus[0] == 6) {
                    strStatus = AspenConstants.STR_Closed_Done;
                }

                //prevent Blind DML
                if(strCurrentComplaintInvestigationStatus != strStatus){
                    Update (New CMPL123CME__Complaint__c(Id = objInvestigation.CMPL123CME__Complaint__c, Investigation_Status__c = strStatus));
                }
            }
        }
    }
}