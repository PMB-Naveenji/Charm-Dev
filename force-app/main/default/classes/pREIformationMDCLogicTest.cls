/* 
* @why  : To Test all scenarios on the class pREInformationMDCLogic
* @when : CreatedDate : 26-SEP-2024  ModifiedDate : 
* @what : pREIformationMDCLogicTest Test Class
*/
@isTest
private class pREIformationMDCLogicTest {
    
    /**
* @Method       : setupData
* @Description  : Create Test Data
**/  
    @testSetup static void setupData() {
        //Create pRE_Information__c
        pRE_Information__c objPreInfo = (pRE_Information__c) TestDataFactory.createSObject(
                new pRE_Information__c(), true);
        TestUtil.setupMDC(
                pREIformationMDCLogic.class,
                pRE_Information__c.getSObjectType(),
                pRE_Information__c.Cause_of_Death_Injury_Potential_Injury__c
        );
        TestUtil.setupMDC(
            pREIformationProdEvalMDCLogic.class,
            pRE_Information__c.getSObjectType(),
            pRE_Information__c.Extent_of_fire_smoke_damage__c
        );
    }
    
    /**
* @Method       : CustomValidation
* @Description  : Test method to cover CustomValidation method in pREInformationMDCLogic Class
**/
    @isTest
    static void CustomValidation() {
        Test.startTest();
        pRE_Information__c objPreInfo = [SELECT Id, Cause_of_Death_Injury_Potential_Injury__c FROM pRE_Information__c LIMIT 1];
        objPreInfo.Cause_of_Death_Injury_Potential_Injury__c = 'Test';
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