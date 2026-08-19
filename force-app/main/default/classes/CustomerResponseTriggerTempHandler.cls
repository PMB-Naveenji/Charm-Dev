/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : CustomerResponseTriggerTempHandler.
* @Why   : Update the checkbox based on specified condition W-001256 AC#3.
* @When  : 23-MAR-2017.
* @Where : CustomerResponseTriggerTempHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017         Work ID / Case ID        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    25-AUG-2020         Code Audit               Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class CustomerResponseTriggerTempHandler {

    /*
    * @Method       : afterUpdateEventHandler.
    * @Description  : Method to update child attachment record based on parent record customer response object
    *                 when it is in closed-done status.
    * @Invoke       : From Customer_Response_AuditTrigger on after update event.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterUpdateEventHandler() {
        /*
        List < Customer_Response__c > newCustomerResponses = (List < Customer_Response__c > ) Trigger.New;
        List < Attachment__c > attachementListToUpdate = new List < Attachment__c > ();
        List < Attachment__c > attachementList = new List < Attachment__c > ();
        Set < String > parentIdSet = new Set < String > ();
        for (Customer_Response__c customerRes: newCustomerResponses) {
            if (customerRes.CMPL123_WF_Status__c == 'Closed-Done') {
                parentIdSet.add(customerRes.id);
            }
        }
        if (parentIdSet != null && parentIdSet.size() > 0) {
            for (Attachment__c attRec: [SELECT Send_to_CMSNext__c, Attachment_Type__c, Customer_Response__c
                    FROM Attachment__c WHERE Customer_Response__c =: parentIdSet
                ]) {
                if (attRec.Attachment_Type__c == 'Customer Complaint Response' || attRec.Attachment_Type__c == 'Customer Letter') {
                    attachementList.add(attRec);
                }
            }
            if (attachementList != null && attachementList.size() > 0) {
                for (Attachment__c attRec: attachementList) {
                    if (attRec.Send_to_CMSNext__c == False) {
                        //attRec.Send_to_CMSNext__c = True;
                        attachementListToUpdate.add(attRec);
                    }
                }
            }
            if (attachementListToUpdate != null && attachementListToUpdate.size() > 0) {
                update attachementListToUpdate;
            }
        }
*/
    }

}