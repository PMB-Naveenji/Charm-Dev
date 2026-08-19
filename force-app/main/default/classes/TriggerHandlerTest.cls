/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TriggerHandlerTest.
* @Why   : To test functionality of TriggerHandler class.
* @When  : 03-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  03-JUN-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class TriggerHandlerTest {
    /*
    * @Method       : test.
    * @Description  : To test TriggerHandler functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        TriggerHandler handler = new TriggerHandler();

        Test.startTest();
        Boolean isTriggerExecuting = handler.isTriggerExecuting;
        handler.isTriggerExecuting = true;
        handler.context = TriggerHandler.TriggerContext.BEFORE_INSERT;
        Boolean validateRunResult = handler.validateRun();
        handler.run();
        handler.setMaxLoopCount(10);
        handler.clearMaxLoopCount();
        handler.addToLoopCount();

        TriggerHandler.LoopCount loopCount = new TriggerHandler.LoopCount();
        Integer maxLoopCount = loopCount.getMax();
        loopCount.getCount();
        loopCount.exceeded();

        String handlerName = 'TriggerHandler';
        TriggerHandler.bypass(handlerName);
        TriggerHandler.clearBypass(handlerName);
        TriggerHandler.isBypassed(handlerName);
        TriggerHandler.clearAllBypasses();

        handler.setTriggerContext(null, true);
        System.assertEquals(TriggerHandler.TriggerContext.BEFORE_INSERT, handler.context);
        handler.setTriggerContext('before insert', true);
        System.assertEquals(TriggerHandler.TriggerContext.BEFORE_INSERT, handler.context);
        handler.setTriggerContext('before update', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.BEFORE_UPDATE, handler.context);
        handler.setTriggerContext('before delete', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.BEFORE_DELETE, handler.context);
        handler.setTriggerContext('after insert', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.AFTER_INSERT, handler.context);
        handler.setTriggerContext('after update', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.AFTER_UPDATE, handler.context);
        handler.setTriggerContext('after delete', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.AFTER_DELETE, handler.context);
        handler.setTriggerContext('after undelete', true);
        handler.run();
        System.assertEquals(TriggerHandler.TriggerContext.AFTER_UNDELETE, handler.context);
        Test.stopTest();

        System.assertEquals(5, maxLoopCount);
        System.assert(validateRunResult);
        System.assertEquals(false, isTriggerExecuting);
    }
}