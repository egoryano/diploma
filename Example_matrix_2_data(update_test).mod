/*********************************************
 * OPL 12.8.0.0 Model
 * Author: Diego
 * Creation Date: 16 апр. 2019 г. at 15:55:54
 *********************************************/
//параметры
int n =...; // число станций
range stations =1..n;
int t =...; // число дней в одном горизонте планирования
range iterations=1..t;
range iterations_1=1..t-1; // массив для вагонов, прибывающих не в стартовый день
range iterations2=t+1..20; // массив для второго горизонта планирования
float Price_p[stations][stations]=...; // тарифы на порожние перегоны
int Time_p[stations][stations]=...; // время порожних перегонов
float Price_z[stations][stations]=...; // тарифы на груженые перегоны
int Time_z[stations][stations]=...; // время на груженые перегоны
int Quantity_z[stations][stations]=...; // заявки на груженые перегоны
int Start[stations]=...; // начальное положение вагонов на станциях
int NI[stations][iterations_1]=...; // вагоны, освободившиеся к моменту времени t с предыдущего месяца
//переменные решения
dvar int+ x[iterations][stations][stations]; // груженые перегоны искомые
dvar int+ y[iterations][stations][stations]; // порожние перегоны искомые
dvar int+ x2[iterations2][stations][stations]; // груженые перегоны на 2-ом горизонте планирования
dvar int+ y2[iterations2][stations][stations]; // порожние перегоны на 2-ом горизонте планирования

dexpr float revenue1 = sum(t in iterations, i in stations, j in stations) Price_z[i][j]*x[t][i][j];
dexpr float cost1 = sum(t in iterations, i in stations, j in stations) Price_p[i][j]*y[t][i][j];
dexpr float revenue2 = sum(t in iterations2, i in stations, j in stations) Price_z[i][j]*x2[t][i][j];
dexpr float cost2 = sum(t in iterations2, i in stations, j in stations) Price_p[i][j]*y2[t][i][j];

dexpr float profit = revenue1-cost1+revenue2-cost2;
maximize profit;

subject to{
	// стартовое положение вагонов
	forall(i in stations)
	  start:
	  sum(j in stations, t in iterations: t == 1) (x[t][i][j]+y[t][i][j])==Start[i];
	// груженые перегоны не должны превышать объем заявок  
	forall(i in stations, j in stations)
	  zayvki:
	  sum(t in iterations) x[t][i][j] <=Quantity_z[i][j];
	// балансовое уравнение: сумма вагонов, приехавших к t должна быть равна сумме уехавших вагонов в t+1
	// интерпретация: все, что уезжает в момент времени t (период 1 день), может уехать в
	// любой момент этого дня, главное не в следующий день
	forall (i in stations, t in iterations: t<10)
	  balans:
	  sum(tt in iterations: tt<=t)
	    (sum(ii in stations: tt+Time_z[ii][i]==t) x[tt][ii][i]
	    +sum(ii in stations: tt+Time_p[ii][i]==t) y[tt][ii][i])
	  +NI[i][t]
	  -sum(jj in stations) (x[t+1][i][jj]+y[t+1][i][jj])==0;
	// дополнительные блок для учета двух одинаковых горизонтов планирования
	// стартовое положение вагонов
	forall(i in stations)
	  start2:
	  sum(t in iterations: t==10) (y[t][i][i]) ==
	  sum(j in stations, t in iterations2: t == 11) (x2[t][i][j]+y2[t][i][j]);  	
	// груженые перегоны не должны превышать объем заявок 
	forall(i in stations, j in stations)
	  zayvki2:
	  sum(t in iterations2) x2[t][i][j] <=Quantity_z[i][j];
	// балансовое уравнение: сумма вагонов, приехавших к t должна быть равна сумме уехавших вагонов в t+1
	// интерпретация: все, что уезжает в момент времени t (период 1 день), может уехать в
	// любой момент этого дня, главное не в следующий день
	forall (i in stations, t in iterations2: t<20)
	  balans2:
	  sum(tt in iterations2: tt<=t)
	    (sum(ii in stations: tt+Time_z[ii][i]==t) x2[tt][ii][i]
	    +sum(ii in stations: tt+Time_p[ii][i]==t) y2[tt][ii][i])
	    +sum(t1 in iterations)
	      	(sum(iii in stations: t1+Time_z[iii][i]==t) x[t1][iii][i]
	      	+sum(iii in stations: t1+Time_p[iii][i]==t) y[t1][iii][i])
	      		-sum(jj in stations) (x2[t+1][i][jj]+y2[t+1][i][jj])==0;
}
	// записываем список груженых и порожних перегонов в файл Excel
tuple Tuple{
	int t;
	int i;
	int j;
	int value;
}
{Tuple} Setz = {<t,i,j,x[t][i][j]> | t in iterations, i in stations, j in stations: x[t][i][j]>0};
{Tuple} Setp = {<t,i,j,y[t][i][j]> | t in iterations, i in stations, j in stations: y[t][i][j]>0};