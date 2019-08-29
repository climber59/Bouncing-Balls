%{
ball can get stuck on an edge if the bounce is just wrong
- often happens during a figure jump

variable # of figures?
- creating would be done with a for loop
- bounce/overlaps would all have to be done with a for-loop
- doOverlap would need arguments
%}
function [] = doubleWindowBall()
	clc
	
	f = [];
	ax = [];
	ball = [];
	
	v = 1;
	dt = 0.001;
% 	dt = 0.5;
	
	
	figureSetup();
	run();
	
	function [] = run()
		while all(ishandle(f))
			j = false;
			onTop = find(gcf==f);
			other = (-(onTop*2-3)+3)/2;
			
			vx = ball.UserData.v*cos(ball.UserData.t);
			vy = ball.UserData.v*sin(ball.UserData.t);
			dx = vx*dt;
			dy = vy*dt;
			
			x = ball.UserData.x + dx;
			y = ball.UserData.y + dy;
			
			%===================================================================================
			% this is where the hard part starts
			
			% detect overlap
			overlap = doOverlap();
			
			if ~overlap
				if x<=0 || x>=ball.Parent.XLim(2) %bounce on right/left wall
					vx = -vx;
				end
				if y>=ball.Parent.YLim(2) || y<=0 % bounce on bot/top wall
					vy = -vy;
				end
			else % there is an overlap
				if ball.UserData.axis == other
					if ballInRect(f(onTop)) % jump to front figure
						[x,y] = jump(other,onTop);
					else
						if x<=0 || x>=ball.Parent.XLim(2)%bounce on left/right wall
							vx = -vx;
						end
						if y>=ball.Parent.YLim(2) || y<=0 % bounce on top/bot wall
							vy = -vy;
						end
					end

				else %overlapping and on the front figure
					j = false;
					bo = ballInRect(f(other));
					if x<=0 % bounce on left wall
						if bo
							j = true;
						else
							vx = -vx;
						end
					elseif x>=ball.Parent.XLim(2) %bounce on right wall
						if bo
							j = true;
						else
							vx = -vx;
						end
					elseif y>=ball.Parent.YLim(2) % bounce on top wall
						if bo
							j = true;
						else
							vy = -vy;
						end
					elseif y<=0 % bounce on bot wall
						if bo
							j = true;
						else
							vy = -vy;
						end
					end
				end	
			end
			
			ball.XData = ball.XData + dx;
			ball.YData = ball.YData + dy;
			ball.UserData.x = x;
			ball.UserData.y = y;
			ball.UserData.t = atan2(vy, vx);
			
			if j
				jump(onTop,other);
			end
					
			pause(dt);
			
			
			
		end
	end
	
	function [x,y] = jump(from, to)
		%convert axis x,y to screen x,y, to new axis x,y
		x = ball.UserData.x + f(from).Position(1) - f(to).Position(1);
		y = ball.UserData.y + f(from).Position(2) - f(to).Position(2);

		ball.UserData.x = x;
		ball.UserData.y = y;
		ball.XData = ball.UserData.px + x;
		ball.YData = ball.UserData.py + y;


		ball.UserData.axis = to;
		ball.Parent = ax(to);
	end
	
	function [] = figureSetup()
		f = gobjects(2,1);
		ax = gobjects(2,1);
		
		f(1) = figure(1);
		clf
		f(1).MenuBar = 'none';
		f(1).UserData = 1;
		f(1).SizeChangedFcn = @resize;
		
		ax(1) = axes(...
			'Parent',f(1),...
			'Position',[0 0 1 1],...
			'XTick',[],...
			'YTick',[],...
			'XLim',[0 f(1).Position(3)],...
			'YLim',[0,f(1).Position(4)],...
			'Box','on');
		axis equal
		ylim manual
		xlim manual
		
		f(2) = figure(2);
		clf
		f(2).MenuBar = 'none';
		f(2).UserData = 2;
		f(2).SizeChangedFcn = @resize;

		ax(2) = axes(...
			'Parent',f(2),...
			'Position',[0 0 1 1],...
			'XTick',[],...
			'YTick',[],...
			'XLim',[0 f(2).Position(3)],...
			'YLim',[0,f(2).Position(4)],...
			'Box','on');
		axis equal
		ylim manual
		xlim manual
		
		s = get(0,'ScreenSize');
		a = (s(3)-f(1).Position(3)-f(2).Position(3))/2;
		f(1).Position(1) = a;
		f(2).Position(1) = a + f(1).Position(3)-10;
		
		t=linspace(0,2*pi,24);
		x = cos(t)*7;
		y = sin(t)*7;
		ball = patch(f(2).Position(3)/2+x,f(2).Position(4)/2+y,[0 0 0]);
		ball.UserData.x = f(2).Position(3)/2;
		ball.UserData.y = f(2).Position(4)/2;
		ball.UserData.v = v/dt;
		ball.UserData.t = 2*pi*rand;
		ball.UserData.px = x;
		ball.UserData.py = y;
		ball.UserData.axis = 2;
	end
	
	function [o] = doOverlap()
		o = false;
		% If one rectangle is on left side of other
		if f(1).Position(1) > sum(f(2).Position([1,3])) || f(2).Position(1) > sum(f(1).Position([1,3]))
			return
		end
		% If one rectangle is above other
		if sum(f(1).Position([2,4])) < f(2).Position(2) || sum(f(2).Position([2,4])) < f(1).Position(2)
			return
		end
		
		o = true;
	end
	
	function [o] = ballInRect(fig)
		x = ball.UserData.x + ball.Parent.Parent.Position(1);
		y = ball.UserData.y + ball.Parent.Parent.Position(2);
		o = false;
		% If one rectangle is on left side of other
		if x > sum(fig.Position([1,3])) || fig.Position(1) > x
			return
		end
		% If one rectangle is above other
		if y < fig.Position(2) || sum(fig.Position([2,4])) < y
			return
		end
		
		o = true;
	end
	
	function [] = resize(src,~)
		a = src.Children;
		a.XLim(2) = src.Position(3);
		a.YLim(2) = src.Position(4);

		% need to check if ball is now outside visible axes
		if src == ball.Parent.Parent && (ball.UserData.x >= a.XLim(2) || ball.UserData.y >= a.YLim(2))
			ball.UserData.x = a.XLim(2)/2;
			ball.UserData.y = a.YLim(2)/2;
			ball.XData = ball.UserData.px + ball.UserData.x;
			ball.YData = ball.UserData.py + ball.UserData.y;
		end
	end
end











