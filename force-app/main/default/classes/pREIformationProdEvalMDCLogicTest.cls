/* 
* @why  : To Test all scenarios on the class pREIformationProdEvalMDCLogic
* @when : CreatedDate : 26-JUN-2026  ModifiedDate : 26-JUN-2026
* @what : pREIformationProdEvalMDCLogicTest Test Class
*/
@isTest
public class pREIformationProdEvalMDCLogicTest {
    /**
    * @Method       : setupData
    * @Description  : Create Test Data
    **/
    @testSetup 
    public static void setupData() {
        //Create pRE_Information__c
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);
        
        // Create Product Evaluation record
        CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(
                CMPL123CME__Complaint__c = complaintTicket.Id,
                Conclusion_Summary__c = 'Conslusion Summarry test1',
                Product_Evaluation_Type__c = 'Lot to lot variability',
                Additional_Action_Taken__c = 'No',
                Close_to_Threshold__c = 'Yes',
                Approval_Date__c = System.today()
            ),  false);
        // Create pRE Information record associated with the Complaint.
        pRE_Information__c objPreInfo = (pRE_Information__c) TestDataFactory.createSObject(
            new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaintTicket.Id),
            true
        );
        TestUtil.setupMDC(
            pREIformationProdEvalMDCLogic.class,
            pRE_Information__c.getSObjectType(),
            pRE_Information__c.Extent_of_fire_smoke_damage__c
        );
    }
    
    @isTest
    public static void CustomValidationPositiveTest() {
        Test.startTest();
        pRE_Information__c objPreInfo = [SELECT Id, Cause_of_Death_Injury_Potential_Injury__c FROM pRE_Information__c LIMIT 1];
        objPreInfo.Extent_of_fire_smoke_damage__c = 'Test';
        objPreInfo = (pRE_Information__c) TestDataFactory.updateSObject(objPreInfo);
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :objPreInfo.Id
            AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
}