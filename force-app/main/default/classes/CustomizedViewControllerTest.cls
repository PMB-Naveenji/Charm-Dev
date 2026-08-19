/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CustomizedViewControllerTest.
* @Why   : Test class to handle different scenarios from CustomizedViewController.
* @When  : 23-MAR-2017.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  23-MAR-2017            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                  08-SEP-2020            PMD                             Added assertion into 'customizedViewController' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class CustomizedViewControllerTest {
    /*
    * @Method       : customizedViewController.
    * @Description  : To test the CustomizedViewController functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void customizedViewController() {
        // Test Data
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = new CMPL123CME__Complaint__c(RecordTypeId = complaintRecTypeId);
        insert complaint;
        Ticket_Note__c ticketNote = new Ticket_Note__c(Ticket__c = complaint.id);
        insert ticketNote;
        Meaningful_Data__c meaningfulData = new Meaningful_Data__c(Compliant__c = complaint.id);
        insert meaningfulData;
        Update meaningfulData;

        Activity__c activityRec = new Activity__c(Complaint__c = complaint.id );
        insert activityRec;
        Re_Open_Justification__c reopenRec = new Re_Open_Justification__c(Complaint__c = complaint.id );
        insert reopenRec;
        Test.startTest();
        PageReference pageRef = Page.CustomizedViewPage;
        Test.setCurrentPage(pageRef);
        // calling for Ticket Note
        ApexPages.currentPage().getParameters().put('Id',ticketNote.id);
        ApexPages.currentPage().getParameters().put('objName','Ticket_Note__c');
        CustomizedViewController viewctrl1 = new CustomizedViewController (new ApexPages.StandardController(complaint));
        // calling for Meaningful Data
        ApexPages.currentPage().getParameters().put('Id',meaningfulData.id);
        ApexPages.currentPage().getParameters().put('objName','Meaningful_Data__c');
        CustomizedViewController viewctr2 = new CustomizedViewController (new ApexPages.StandardController(complaint));
        // calling for Activity
        ApexPages.currentPage().getParameters().put('Id',activityRec.id);
        ApexPages.currentPage().getParameters().put('objName','Activity__c');
        CustomizedViewController viewctr3 = new CustomizedViewController (new ApexPages.StandardController(complaint));
         // calling for Re Open Justification
        ApexPages.currentPage().getParameters().put('Id',reopenRec.id);
        ApexPages.currentPage().getParameters().put('objName','Re_Open_Justification__c');
        CustomizedViewController viewctr4 = new CustomizedViewController (new ApexPages.StandardController(complaint));
        delete meaningfulData;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Meaningful_Data__c]);
    }
}