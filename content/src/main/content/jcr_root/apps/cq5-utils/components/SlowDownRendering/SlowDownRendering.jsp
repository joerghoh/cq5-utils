<%@page session="false"%><%
%><%@include file="/libs/foundation/global.jsp"%><%

	int delay = properties.get("delay",5);
	Thread.sleep(delay*1000);

%>
<p>Sleeping for <%=delay %> seconds during rendering.</p>
