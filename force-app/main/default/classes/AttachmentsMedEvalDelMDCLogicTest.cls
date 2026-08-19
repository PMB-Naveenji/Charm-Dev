/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : AttachmentsMedEvalDelMDCLogicTest.
* @Why   : AttachmentsMedEvalDelMDCLogicTest class for the AttachmentsWithMedEvalDeletionMDCLogic class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                    Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                18-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class AttachmentsMedEvalDelMDCLogicTest {
    /*
    * @Method       : AttachmentsWithMedEvalDeletionMDCLogicTestSetup.
    * @Description  : To test the AttachmentsWithMedEvalDeletionMDCLogic class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static public void AttachmentsWithMedEvalDeletionMDCLogicTestSetup () {
        Translation_Task__c task = new Translation_Task__c();
        insert task;
        update task;
        delete task;
        System.assertEquals(0, [SELECT COUNT() FROM Translation_Task__c]);
    }
}