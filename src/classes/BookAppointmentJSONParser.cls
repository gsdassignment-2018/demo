public class BookAppointmentJSONParser{
    public String Subject;  //
    public String AppointmentDate;  //2018-11-16
    public String StartTime;    //9:00 :00.000Z
    public String EndTime;  //9:30 :00.000Z
    public static BookAppointmentJSONParser parse(String json){
        return (BookAppointmentJSONParser) System.JSON.deserialize(json, BookAppointmentJSONParser.class);
    }
}