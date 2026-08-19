/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TriggerHandler.
* @Why   : To provide dynamic context execution.
* @When  : 23-MAR-2017.
* @Where : From all trigger handlers.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  23-MAR-2017            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public virtual class TriggerHandler {
    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    private static Set<String> singletonSet;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        singletonSet = new Set<String>();
    }

    /*
    * @Method       : TriggerHandler.
    * @Description  : Constructor.
    * @Invoke       : From all handler classes.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TriggerHandler() {
        this.setTriggerContext();
    }

/**************************************** public instance methods ****************************************/

    /*
    * @Method       : run.
    * @Description  : Main method that will be called during execution.
    * @Invoke       : From all triggers.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void run() {

        if(!validateRun()){
          return;
        }

        // This set will ensure the handlers are called once per transaction.
        //if(!singletonSet.add(getHandlerName() + this.context)) return;

        addToLoopCount();

        // dispatch to the correct handler method
        if(this.context == TriggerContext.BEFORE_INSERT) {
            this.beforeInsert();
        } else if(this.context == TriggerContext.BEFORE_UPDATE) {
            this.beforeUpdate();
        } else if(this.context == TriggerContext.BEFORE_DELETE) {
            this.beforeDelete();
        } else if(this.context == TriggerContext.AFTER_INSERT) {
            this.afterInsert();
        } else if(this.context == TriggerContext.AFTER_UPDATE) {
            this.afterUpdate();
        } else if(this.context == TriggerContext.AFTER_DELETE) {
            this.afterDelete();
        } else if(this.context == TriggerContext.AFTER_UNDELETE) {
            this.afterUndelete();
        }

    }

    /*
    * @Method       : setMaxLoopCount.
    * @Description  : Invokes a getHandlerName() method and stores it in a variable.
    *                   After that checks If TriggerHandler.loopCountMap does not contain a key with a respective handler name.
    * @Invoke       : From clearMaxLoopCount() method.
    * @Return       : N/A.
    * @Params       : Integer max.
    */
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    /*
    * @Method       : clearMaxLoopCount.
    * @Description  : Invokes setMaxLoopCount() method with passing -1 as a parameter.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

/**************************************** public static methods ****************************************/

    /*
    * @Method       : bypass.
    * @Description  : Invokes TriggerHandler.bypassedHandlers.add() method with passing handlerName as a parameter.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : String handlerName.
    */
    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    /*
    * @Method       : clearBypass.
    * @Description  : Invokes TriggerHandler.bypassedHandlers.remove() method with passing handlerName as a parameter.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : String handlerName.
    */
    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    /*
    * @Method       : isBypassed.
    * @Description  : Invokes TriggerHandler.bypassedHandlers.contains() method with passing handlerName as a parameter.
    * @Invoke       : N/A.
    * @Return       : Boolean.
    * @Params       : String handlerName.
    */
    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    /*
    * @Method       : clearAllBypasses.
    * @Description  : Invokes TriggerHandler.bypassedHandlers.clear() method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

/**************************************** private instancemethods ****************************************/

    /*
    * @Method       : setTriggerContext.
    * @Description  : Invokes setTriggerContext() method with passing null and false params.
    * @Invoke       : From constructor method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    /*
    * @Method       : setTriggerContext.
    * @Description  : It sets the context in which the trigger is supposed to run.
    * @Invoke       : From setTriggerContext() method.
    * @Return       : N/A.
    * @Params       : String ctx, Boolean testMode.
    */
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
           (ctx != null && ctx == 'before insert')) {
               this.context = TriggerContext.BEFORE_INSERT;
           } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
                     (ctx != null && ctx == 'before update')){
                         this.context = TriggerContext.BEFORE_UPDATE;
                     } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
                               (ctx != null && ctx == 'before delete')) {
                                   this.context = TriggerContext.BEFORE_DELETE;
                               } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
                                         (ctx != null && ctx == 'after insert')) {
                                             this.context = TriggerContext.AFTER_INSERT;
                                         } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
                                                   (ctx != null && ctx == 'after update')) {
                                                       this.context = TriggerContext.AFTER_UPDATE;
                                                   } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
                                                             (ctx != null && ctx == 'after delete')) {
                                                                 this.context = TriggerContext.AFTER_DELETE;
                                                             } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
                                                                       (ctx != null && ctx == 'after undelete')) {
                                                                           this.context = TriggerContext.AFTER_UNDELETE;
                                                                       }
    }

    /*
    * @Method       : addToLoopCount.
    * @Description  : It counts the number of time the trigger is executed.
    * @Invoke       : From run() method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                String customLabel = System.Label.General_Trigger_Handler_Loop_Count;
                List<String> errorMsg = customLabel.split('~');
                throw new TriggerHandlerException(errorMsg[0] + String.valueOf(max) +errorMsg [1] + handlerName);
            }
        }
    }

    /*
    * @Method       : validateRun.
    * @Description  : It ensures that the trigger continues to run.
    * @Invoke       : From run() method.
    * @Return       : Boolean.
    * @Params       : N/A.
    */
    @TestVisible
    private Boolean validateRun() {
        if(!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException(System.label.General_Trigger_Handler);
        }
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }
        return true;
    }

    /*
    * @Method       : getHandlerName.
    * @Description  : It fetches the Trigger handler name of the currently executing trigger.
    * @Invoke       : From setMaxLoopCount(), addToLoopCount(), validateRun() methods.
    * @Return       : String.
    * @Params       : N/A.
    */
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

/**************************************** context methods ****************************************/

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}

/**************************************** inner classes ****************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {

            if(this.max < 0){
              return false;
            }
            if(this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
            AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
            AFTER_UNDELETE
            }

    // exception class
    public class TriggerHandlerException extends Exception {}
}