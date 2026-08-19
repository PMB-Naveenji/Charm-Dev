/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : EvaluationHandlerTemp.
* @Why   : Updates the Customer Reply of Customer Response from KI Log.
* @When  : 23-MAR-2017.
* @Where : From CMPL123CME_Investigation_AuditTrigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    17-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class EvaluationHandlerTemp {

    public static Boolean recursionHandler = false;

    /*
    * @Method       : afterEventHandler.
    * @Description  : Updates the Customer Reply of Customer Response from KI Log.
    * @Invoke       : From CMPL123CME_Investigation_AuditTrigger on after insert and update events.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void afterEventHandler() {
        TicketUtil.addTrace('EvaluationHandlerTemp.afterEventHandler');
        if (!recursionHandler) {
            recursionHandler = true;
            List<CMPL123CME__Investigation__c> newInvList = (List<CMPL123CME__Investigation__c>) Trigger.new;
            Set<String> complaintIds = new Set<String>();
            Set<String> KILogIds = new Set<String>();
            for (CMPL123CME__Investigation__c investigation : newInvList) {
                if (investigation.CMPL123CME__Complaint__c != null && investigation.KI_Log__c != null) {
                    complaintIds.add(investigation.CMPL123CME__Complaint__c);
                    KILogIds.add(investigation.KI_Log__c);
                }
            }
            if ((KILogIds != null && KILogIds.size() > 0) && (complaintIds != null && complaintIds.size() > 0)) {
                List<Customer_Response__c> customerResponseUpdateList = new List<Customer_Response__c>();
                //Defect #1611 fix BEGIN
                List<Customer_Response__c> customerResponseList = [
                        SELECT Id, Event__c, Customer_Reply__c, CMPL123_WF_Status__c
                        FROM Customer_Response__c
                        WHERE Event__c = :complaintIds
                        AND (NOT CMPL123_WF_Status__c LIKE 'Close%')
                ];
                //Defect #1611 fix END
                if (customerResponseList != null && customerResponseList.size() > 0) {
                    List <KI_Log__c> KILogList = [SELECT Id, Customer_Reply__c FROM KI_Log__c WHERE id = :KILogIds];
                    if ((customerResponseList != null && customerResponseList.size() > 0) && (KILogList != null && KILogList.size() > 0)) {
                        for (Customer_Response__c cusResponse : customerResponseList) {
                            for (KI_Log__c KILogRec : KILogList) {
                                if (cusResponse.Customer_Reply__c == null && KILogRec.Customer_Reply__c != null) {
                                    cusResponse.Customer_Reply__c = KILogRec.Customer_Reply__c;
                                    customerResponseUpdateList.add(cusResponse);
                                }
                            }
                        }
                    }
                }
                if (customerResponseUpdateList != null && customerResponseUpdateList.size() > 0) {
                    update customerResponseUpdateList;
                }
            }
        }
    }
}