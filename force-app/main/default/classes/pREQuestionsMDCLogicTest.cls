/* 
* @why  : To Test all scenarios on the class pREQuestionsMDCLogic
* @when : CreatedDate : 26-OCT-2018  ModifiedDate : 26-OCT-2018
* @what : pREQuestionsMDCLogicTest Test Class
*/
@isTest
private class pREQuestionsMDCLogicTest {
    
    /**
* @Method       : setupData
* @Description  : Create Test Data
**/  
    @testSetup static void setupData() {
        
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId
                ), true);
        // Create Medical Evaluation    
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'Opened'
                ), true);
        
        //Creating pRE_Information__c
        pRE_Information__c objPreInformation = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
            pRE_Comments__c = 'Test',
            Cause_of_fire_smoke__c = 'Test Fire Smoke',
            Extent_of_fire_smoke_damage__c = 'Test Damage',
            Sample_Type_Storage_Condition__c = 'Test Condition',
            Device_Storage_Condition__c = 'Test Storage',
            Cause_of_exposure_potential_exposure__c = 'Test Exposure',
            Cause_of_Death_Injury_Potential_Injury__c = 'Test Injuiry',
            Complaint__c = complaint.Id),
            true);
        //Create pRE_Question__c
        pRE_Question__c objPreQuestion = (pRE_Question__c) TestDataFactory.createSObject(
                new pRE_Question__c(pRE_Information__c= objPreInformation.Id), true);
        TestUtil.setupMDC(
                pREQuestionsMDCLogic.class,
                pRE_Question__c.getSObjectType(),
                pRE_Question__c.Answer__c
        );
    }
    
    /**
* @Method       : CustomValidation
* @Description  : Test method to cover CustomValidation method in pREQuestionsMDCLogic Class
**/
    @isTest
    static void CustomValidation() {
        Test.startTest();
        pRE_Question__c objPreQuestion = [SELECT Id, Answer__c FROM pRE_Question__c LIMIT 1];
        objPreQuestion.Answer__c = 'Test Answer';
        objPreQuestion = (pRE_Question__c) TestDataFactory.updateSObject(objPreQuestion);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :objPreQuestion.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
    
    
    /**
    * @Method       : customPreQuestionTest
    * @Description  : Test method to verify that an MDC record is created when the Answer__c field on a 
    * 				  pRE Question record is populated and the related Medical Evaluation record status is 'Closed-Voided'
    **/
    @isTest
    public static void customPreQuestionTest(){
        Test.StartTest();  
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        CMPL123CME__Questionnaire__c medEval = [SELECT Id,CMPL123CME__Complaint__c, CMPL123_WF_Status__c FROM CMPL123CME__Questionnaire__c LIMIT 1];
        medEval.CMPL123_WF_Status__c = 'Closed-Voided';
        update medEval; 
        pRE_Question__c objPreQuestion = [SELECT Id, Answer__c,Related_Ticket_Id__c FROM pRE_Question__c LIMIT 1];
        objPreQuestion.Answer__c = 'Test Answer';
        objPreQuestion = (pRE_Question__c) TestDataFactory.updateSObject(objPreQuestion);
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(1, mdcCount);
        Test.StopTest();
    }
}