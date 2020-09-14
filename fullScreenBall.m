%{

%}
function [] = fullScreenBall()
	clc
	
	f = [];
	ax = [];
	ball = [];
	g = groot;
	screen = get(0,'ScreenSize');
	
	dt = 0.01;
	v = 6;

	n = 4;
	
	fprintf('\n\nMove the 4 figures around to follow the ball\nClose any figure to stop\n')
	figureSetup();
	run();
	
	function [] = run()
		while all(ishandle(f)) % run while all figures still exist
			
			vx = ball.UserData.v*cos(ball.UserData.t);
			vy = ball.UserData.v*sin(ball.UserData.t);
			dx = vx*dt;
			dy = vy*dt;
			
			x = ball.UserData.x + dx;
			y = ball.UserData.y + dy;
			
			if x<=0 || x>=screen(3) %bounce on right/left edge of the screen (I don't know how it works on dual monitors)
				vx = -vx;
			end
			if y>=screen(4) || y<=0 % bounce on bot/top edge of the screen
				vy = -vy;
			end
			
			
			figOrder = [g.Children.Number];
			overlap = ballInRect(figOrder); % which figures is the ball within
			i = figOrder(find(overlap,1));
			if isempty(i)
				ball.Visible = 'off'; % just make it invisible if it should be off-figure
			else
				% put ball on f(i)
				xa = x - f(i).Position(1);
				ya = y - f(i).Position(2);
				ball.XData = ball.UserData.px + xa;
				ball.YData = ball.UserData.py + ya;

				if ball.UserData.axis ~= i || strcmp(ball.Visible, 'off') % make it visible and store the current figure index if this is the first time it appeared
					ball.Parent = ax(i);
					ball.UserData.axis = i;
					ball.Visible = 'on';
				end
			end
			
			
			ball.UserData.x = x;
			ball.UserData.y = y;
			ball.UserData.t = atan2(vy, vx);
					
			pause(dt);
			
		end
	end
	
	% create the figures and the ball
	function [] = figureSetup()
		f = gobjects(n,1);
		ax = gobjects(n,1);
		
		for i = 1:n
			f(i) = figure(i);
			clf
			f(i).MenuBar = 'none';
			f(i).UserData = 1;
			f(i).SizeChangedFcn = @resize;

			ax(i) = axes(...
				'Parent',f(i),...
				'Position',[0 0 1 1],...
				'XTick',[],...
				'YTick',[],...
				'XLim',[0 f(i).Position(3)],...
				'YLim',[0,f(i).Position(4)],...
				'Box','on');
			axis equal
			ylim manual
			xlim manual
		end
				
		t=linspace(0,2*pi,24);
		x = cos(t)*7;
		y = sin(t)*7;
		ball = patch(f(1).Position(3)/2+x,f(1).Position(4)/2+y,[0 0 0]); % start within figure 1
		ball.UserData.x = f(1).Position(3)/2 + f(1).Position(1);
		ball.UserData.y = f(1).Position(4)/2 + f(1).Position(2);
		ball.UserData.v = v/dt;
		ball.UserData.t = 2*pi*rand;
		ball.UserData.px = x;
		ball.UserData.py = y;
		ball.UserData.axis = 1;
	end
	
	% returns a bool array. true if the ball is within a figure
	function [o] = ballInRect(fig)
		x = ball.UserData.x;
		y = ball.UserData.y;
		o = ones(size(fig));
		for i = 1:length(fig)
			if f(fig(i)).Position(1) > x || x > sum(f(fig(i)).Position([1,3])) || f(fig(i)).Position(2) > y || y > sum(f(fig(i)).Position([2,4]))
				o(i) = false;
			end
		end
	end
	
	% rescale axes when the figure changes size
	function [] = resize(src,~)
		a = src.Children;
		a.XLim(2) = src.Position(3);
		a.YLim(2) = src.Position(4);
	end
end