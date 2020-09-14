%{
will pass out of rect drawn over it, but can still bounce on oevrlapping
rects and be hidden forever

can pass through very thin rects.

speed boosts? (and slow downs)
-maybe tapping a rect or something changes its function


make brick breaker. same code really, just delete a rect after hitting it
%}
function [] = rectBall()
	clc
	
	f = [];
	ax = [];
	ball = [];
	rects = [];
	circles = [];
	cx = [];
	cy = [];
	paused = false;
	
	v = 2.5;
	dt = 0.005;

	figureSetup();
	h = animatedline(ball.UserData.x,ball.UserData.y);
	h.MaximumNumPoints = 100;
	run();
	
	function [] = run()
		while ishandle(1) && ~paused
			vx = ball.UserData.v*cos(ball.UserData.t);
			vy = ball.UserData.v*sin(ball.UserData.t);
			dx = vx*dt;
			dy = vy*dt;
			
			x0 = ball.UserData.x;
			y0 = ball.UserData.y;
			
			x = x0 + dx;
			y = y0 + dy;
			
			ball.UserData.x = x;
			ball.UserData.y = y;
			ball.XData = ball.XData + dx;
			ball.YData = ball.YData + dy;
			
			if x<=0 || x>=ax.XLim(2) %bounce on right/left wall
				vx = -vx;
			end
			if y>=ax.YLim(2) || y<=0 % bounce on bot/top wall
				vy = -vy;
			end
			
			xb = false;
			yb = false;
			for i = 1:length(rects)
				% inside rect
				if ~(xb && yb) && ~isempty(rects(i).UserData) && between(rects(i).UserData.x1,x,rects(i).UserData.x2) && between(rects(i).UserData.y1,y,rects(i).UserData.y2) 
					% previous x was not inside
					if ~xb && ~between(rects(i).UserData.x1,x0,rects(i).UserData.x2) 
						vx = -vx;
						xb = true;
					elseif ~yb && ~between(rects(i).UserData.y1,y0,rects(i).UserData.y2) %previous y was not insde
						vy = -vy;
						yb = true;
					end
				end
			end
			for i = 1:length(circles)
				xc = circles(i).UserData.x;
				yc = circles(i).UserData.y;
				r = circles(i).UserData.r;
				if dist(x,y,xc,yc) <= r && dist(x0,y0,xc,yc) > r
					m = (y-y0)/(x-x0);
					b = y - m*x;
					
					% find insections of path and circle
					xe1 = (-(2*m*b-2*m*yc - 2*xc) + sqrt((2*m*b-2*m*yc - 2*xc)^2 - 4*(m^2+1)*(xc^2+b^2-2*yc*b+yc^2-r^2)))/(2*m^2+2);
					xe2 = (-(2*m*b-2*m*yc - 2*xc) - sqrt((2*m*b-2*m*yc - 2*xc)^2 - 4*(m^2+1)*(xc^2+b^2-2*yc*b+yc^2-r^2)))/(2*m^2+2);
					% pick the one inbetween x,x0
					d = abs(x-x0);
					if abs(x-xe1) <=d && abs(x0-xe1) <= d && isreal(xe1)
						xe = xe1;
					elseif abs(x-xe2) <=d && abs(x0-xe2) <= d && isreal(xe2)
						xe = xe2;
					else
						continue
					end
					ye = m*xe+b;
					
					t = abs(ball.UserData.t);
					t2 = abs(atan2(ye - yc, xe - xc));

% 					if vy >=0 && ye >= yc % top, pos vy
% 						t3 = -t + 2*t2 - pi;
% 					elseif vy <=0 && ye >= yc % top, neg vy
% 						t3 = t + 2*t2 - pi; %maybe wrongs
% 					elseif vy >=0 && ye <= yc % bot, pos vy
% 						t3 = -t - 2*t2 + pi; %just 1*pi?
% 					else % bot, neg vy
% 						t3 = t - 2*t2 + pi;
% 					end
					t3 = -sign(vy)*t + sign(ye-yc)*(2*t2 - pi);
					
					vx = ball.UserData.v*cos(t3);
					vy = ball.UserData.v*sin(t3);
					ball.XData = ball.UserData.px + xe;
					ball.YData = ball.UserData.py + ye;
					ball.UserData.x = xe;
					ball.UserData.y = ye;
				end
			end
			
			
			ball.UserData.t = atan2(vy, vx);
			
			h.addpoints(x,y)
			pause(dt)
		end
	end
	
	function [] = keyboard(~,evt)
% 		evt.Key
		switch evt.Key
			case 'space'
				paused = ~paused;
				if ~paused
					run();
				end
			case 'backspace'
				delete(rects);
				delete(circles);
				rects = rects(ishandle(rects));
				circles = circles(ishandle(circles));
		end
	end
	
	function [] = click(~,~)
		f.UserData.CurSelectionType = f.SelectionType;
		f.WindowButtonDownFcn = {};
		switch f.SelectionType
			case 'normal' %left click, add rect
				m = ax.CurrentPoint([1,3]);
				ax.UserData = m;
				rects(end+1) = patch([m(1) m(1) m(1) m(1)],[m(2) m(2) m(2) m(2)],[0 0 0]);
				f.WindowButtonMotionFcn = @mouseMove;
			case 'extend' % shift+left click, add circle
				m = ax.CurrentPoint([1,3]);
				ax.UserData = m;
				
				circles(end+1) = patch(m(1) + cx*0,m(2) + cy*0,[0 0 0]);
				circles(end).UserData.x = m(1);
				circles(end).UserData.y = m(2);
				circles(end).UserData.r = 0;
				f.WindowButtonMotionFcn = @mouseMove;
			case 'alt'
				%delete rect
		end
	end
	
	function [] = mouseMove(~,~)
		switch f.UserData.CurSelectionType % f.SelectionType
			case 'normal'
				rects(end).XData([3,4]) = ax.CurrentPoint(1);
				rects(end).YData([2,3]) = ax.CurrentPoint(3);
			case 'extend'
				r = dist(ax.UserData(1),ax.UserData(2),ax.CurrentPoint(1),ax.CurrentPoint(3));
				circles(end).XData = cx*r + ax.UserData(1);
				circles(end).YData = cy*r + ax.UserData(2);
		end
	end
	
	function [] = unclick(~,~)
		switch f.UserData.CurSelectionType %f.SelectionType
			case 'normal'
				f.WindowButtonMotionFcn = [];
				m(1,:) = ax.UserData;
				m(2,:) = ax.CurrentPoint([1,3]);

				rects(end).UserData.x1 = min(m(:,1));
				rects(end).UserData.x2 = max(m(:,1));
				rects(end).UserData.y1 = min(m(:,2));
				rects(end).UserData.y2 = max(m(:,2));
			case 'extend'
				f.WindowButtonMotionFcn = [];
				circles(end).UserData.r = dist(ax.UserData(1),ax.UserData(2),ax.CurrentPoint(1),ax.CurrentPoint(3));
			case 'alt'
				m = ax.CurrentPoint([1,3]);
				i = 1;
				while i <= length(rects)
					if pointInRect(m(1),m(2),rects(i))
						delete(rects(i));
					end
					i = i + 1;
				end
				rects = rects(ishandle(rects));
				
				i = 1;
				while i <= length(circles)
					if circles(i).UserData.r >= dist(m(1),m(2),circles(i).UserData.x,circles(i).UserData.y)
						delete(circles(i));
					end
					i = i + 1;
				end
				circles = circles(ishandle(circles));
		end
		f.WindowButtonDownFcn = @click;
	end
	
	function [o] = pointInRect(x,y,r)
		if r == f
			rx1 = 0;
			rx2 = ax.XLim(2);
			ry1 = 0;
			ry2 = ax.YLim(2);
		else
			rx1 = r.UserData.x1;
			rx2 = r.UserData.x2;
			ry1 = r.UserData.y1;
			ry2 = r.UserData.y2;
		end
		o = true;
		if x < rx1 || x > rx2 || y < ry1 || y > ry2
			o = false;
		end
	end
	
	function [] = figureSetup()
		f = figure(1);
		clf
		f.MenuBar = 'none';
		f.SizeChangedFcn = @resize;
		f.WindowButtonDownFcn = @click;
		f.WindowButtonUpFcn = @unclick;
		f.WindowKeyPressFcn = @keyboard;
		
		ax = axes(...
			'Parent',f,...
			'Position',[0 0 1 1],...
			'XTick',[],...
			'YTick',[],...
			'XLim',[0 f.Position(3)],...
			'YLim',[0,f.Position(4)],...
			'Box','on');
		axis equal
		ylim manual
		xlim manual
		
		t=linspace(0,2*pi,24);
		x = cos(t)*7;
		y = sin(t)*7;
		ball = patch(f(1).Position(3)/2+x,f(1).Position(4)/2+y,[0.5 0.5 0.95],'EdgeColor','none');
		ball.UserData.x = f(1).Position(3)/2;
		ball.UserData.y = f(1).Position(4)/2;
		ball.UserData.v = v/dt;
		ball.UserData.t = pi/4;%2*pi*rand;
		ball.UserData.px = x;
		ball.UserData.py = y;
		
		rects = matlab.graphics.primitive.Patch.empty;
		circles = matlab.graphics.primitive.Patch.empty;
		
		t = linspace(0,2*pi,48);
		cx = cos(t);
		cy = sin(t);
	end
	
	function [] = resize(~,~)
		ax.XLim(2) = f.Position(3);
		ax.YLim(2) = f.Position(4);
		
		if ball.UserData.x > ax.XLim(2) || ball.UserData.y > ax.YLim(2)
			ball.UserData.x = ax.XLim(2)/2;
			ball.UserData.y = ax.YLim(2)/2;
			ball.XData = ball.UserData.px + ball.UserData.x;
			ball.YData = ball.UserData.py + ball.UserData.y;
		end
	end
end

function [itIs] = between(a,b,c)
	itIs = (a <= b && b <= c);
end

function [d] = dist(x1,y1,x2,y2)
	d = sqrt((x1-x2).^2 + (y1-y2).^2);
end