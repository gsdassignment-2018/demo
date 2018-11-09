({
    doInIt : function(component,event,helper)
    {
        var time_options = [] ;
        for(var i = 0 ; i < 24; i++)
        {
            var time_meridian = '' ;
            var time_hour ;
            if(i <12)
            {
                time_meridian = ' AM' ;
                time_hour = i ;
            }
            else
            {
                time_meridian = ' PM' ;
                time_hour = i - 12 ;
            }
            for(var j = 0 ; j < 2 ; j++)
            {
            	var hour = time_hour + 12 ;
                if(time_hour == 0)
                    hour = time_hour + 12 ;
                else
                    hour = time_hour ;
                
                var min = '';
                if(j == 0)
                    min = '00' ;
                else
                   min = '30' ; 
                var time_option = new Object() ;
                time_option.label = hour + ':' + min + time_meridian ;
                time_option.value = (i * 3600000) + (Number(min) * 60000) ;
                time_option.isDisabled = false ;
                time_options.push(time_option) ;
            }
        }
        if(time_options.length > 0)
            component.set('v.TimeOptions',time_options) ;
        
        helper.getAllAppointments(component,event,helper) ;
    },
    showCalender : function(component,event,helper) {
        $(document).ready(function(){
        	$('#calendar').fullCalendar({
                header : {
                    left : 'prev,next,today',
                    center : 'title',
                    right : 'month,basicWeek,basicDay'
                },
                eventLimit : true,
                allDaySlot : true,
                displayEventTime: true,
                event : component.get('v.Appointments') ,
                dayClick : function(date, jsEvent, view) {
                    console.log('A day has been clicked'+date) ;  
                    helper.getDayClickEvent(component,event,helper,date);
                },
                eventClick : function(calEvent, jsEvent, view) {
                    console.log('An event has been clicked '+calEvent.title) ;
                },
                viewRender: function (view, element) {
                    $('#calendar').fullCalendar('removeEvents');
                    $('#calendar').fullCalendar('addEventSource', component.get('v.Appointments'));
                },
            });   
        });
    },
    closeModalJS : function(component,event,helper)
    {
        helper.closeModal(component,event,helper) ;
    },
    saveEvent : function(component,event,helper)
    {
        var recId = component.get('v.recordId') ;
        var saveObjAppointment = component.get('v.Appointment') ;
        if(saveObjAppointment.Subject == '' || saveObjAppointment.Subject == null)
        {
            component.set('v.isError',true) ;
            component.set('v.errMsg','Error:Subject should not be blank.') ;
        }
        else if(saveObjAppointment.AppointmentDate < moment(new Date()).format('MM/DD/YYYY'))
        {
            component.set('v.isError',true) ;
            component.set('v.errMsg','Error:Appointment Date should be greater than or equal to today.') ;
        }
        else if(saveObjAppointment.StartTime == null || saveObjAppointment.EndTime == null)
        {
            component.set('v.isError',true) ;
            component.set('v.errMsg','Error:Start Time/End Time should not be blank.') ;
        }
        else if((saveObjAppointment.EndTime <= saveObjAppointment.StartTime) && ((saveObjAppointment.EndTime - saveObjAppointment.StartTime) <= 0))
        {
            component.set('v.isError',true) ;
            component.set('v.errMsg','Error:Start Time should not be greater than End Time.') ;
        }
        else
        {
            component.set('v.isError',false) ;
            var action = component.get('c.saveAppointment') ;
            action.setParams({appointment : JSON.stringify(saveObjAppointment),contactId : recId}) ;
            action.setCallback(component,function(response){
                var state = response.getState() ;
                if(state == 'SUCCESS')
                {
                    var message = response.getReturnValue() ;
                    if(message == 'SUCCESS')
                    {
                        helper.closeModal(component, event, helper) ;
                        helper.showToast(component, event,'New Appointment is Created','New Appointment is successfully created.','New Appointment is successfully created.','success') ;
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                    else if(message.includes('SINGLE_EMAIL_LIMIT_EXCEEDED'))
                    {
                        component.set('v.isError',true) ;
                        component.set('v.errMsg','Error:Your daily limit of Email has exceeded.') ;
                    }
                    else
                    {
                        component.set('v.isError',true) ;
            			component.set('v.errMsg',message) ;
                    }
                    
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    var errorMessage ;
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            errorMessage = "Error message: " + errors[0].message ;
                            console.log(errorMessage);
                            
                        }
                    } else {
                        errorMessage = 'Unknown error.Please Contact your System Admin.'
                        console.log("errorMessage");
                    }
                    helper.closeModal(component, event, helper) ;
                    helper.showToast(component, event,'An Error has occured',errorMessage,errorMessage,'error') ;
                }
            }); 
            $A.enqueueAction(action) ;
        }
    },
    doChange : function(component,event,helper)
    {
        if(component.get('v.isDateChanged') == true)
            component.set('v.isDateChanged',false) ;
        else
        {
            component.set('v.isDateChanged',true) ;
            helper.getDayClickEvent(component,event,helper,component.get('v.Appointment.AppointmentDate'));
        }
        
	}
})