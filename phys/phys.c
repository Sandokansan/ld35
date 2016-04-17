#include <stdio.h>
#include <chipmunk/chipmunk.h>
#include <chipmunk/chipmunk_structs.h>

#include <math.h>

//int main(void) {}

#define GLOBALS
#include "div.h"

#define to_degrees(X) (X * (180.0 / M_PI))

#define WALL_MAX 1000

int phys_test(void);


static cpVect gravity;
static cpSpace *space;
static cpShape *walls[WALL_MAX];
int wallnum=0;

//static cpBody *ballBody;
//[65535];

int nbody=0;

//static cpShape *ballShape;
static cpFloat timeStep;
static cpVect pos;
static double ang2;

static int init=0;

#define iloc_len (mem[5]+mem[6])
#define imem (mem[8])

struct procbody {
	cpBody *body;
	cpShape *shape;
	int procid;
	struct procbody *next;
	struct procbody *prev;
};
 

struct procbody *bodies; 

void rum(void) {
	int i=getparm();
	retval(0);
}

#define proc(x) ((process *)&mem[x])

void add_fixed_body(void) {

	int diam=getparm();
	int y2=getparm();
	int x2=getparm();
	int y1=getparm();
	int x1=getparm();

	int wallnum =0;
	while(walls[wallnum]!=NULL && wallnum<WALL_MAX) {
		wallnum++;
	}
	if(wallnum>=WALL_MAX) {
		printf("too many walls\n");
		retval(-1);
		return;
	}
//	printf("wallnum: %d\n",wallnum);
	

//	walls[wallnum] = (cpShape*)div_malloc(sizeof(cpShape));

	walls[wallnum] = cpSegmentShapeNew(space->staticBody, cpv(x1,y1), cpv(x2,y2), diam);
	walls[wallnum]->e=0.9;

	cpShapeSetFriction(walls[wallnum], 1);
	cpSpaceAddShape(space, walls[wallnum]);
	
//	wallnum++;
	retval(wallnum);
	
}

void remove_fixed_body(void) {
	int id=getparm();
	
	if(cpSpaceContainsShape(space, walls[id])) {
		cpSpaceRemoveShape(space, walls[id]);
		cpShapeFree(walls[id]);
//		printf("Removed wall %d\n",id);
		walls[id]=NULL;
		retval(0);
	}
	
	retval(id);
	
}

void add_body(void) {
	
	int mid = getparm();
	
	struct procbody *newb = (struct procbody*)div_malloc(sizeof(struct procbody));

	struct procbody *n = bodies->next;
		
	cpFloat radius = 20*(proc(mid)->size*100)/10000;
	
//	printf("size %d, radius %f %d %d %d\n",proc(mid)->size, radius , proc(mid)->reserved.x0,  proc(mid)->reserved.x1,  proc(mid)->radius);

	//*
	//	(((process *)&mem[mid])->size/100);
	cpFloat mass = 10;
	
	// The moment of inertia is like mass for rotation
	// Use the cpMomentFor*() functions to help you approximate it.
	cpFloat moment = cpMomentForCircle(mass, 0, radius, cpvzero);
	
	newb->next = bodies->next;
	newb->prev = bodies;
	if(n!=NULL)
		n->prev = newb;
	

	bodies->next = newb;
	
	newb->body = cpSpaceAddBody(space, cpBodyNew(mass, moment));
	newb->procid = mid;
	
	cpBodySetPosition(newb->body, cpv( ((process *)&mem[mid])->x,((process *)&mem[mid])->y));
	
	newb->shape = cpSpaceAddShape(space, cpCircleShapeNew(newb->body, radius, cpvzero));

	newb->shape->e = 0.75;

//	newb->shape->u = 1;
	
	cpShapeSetFriction(newb->shape, 0.7);
		
//	printf("new body: %d x: %d y:%d\n",mid, ((process *)&mem[mid])->x,((process *)&mem[mid])->y);
	
	retval(0);
}

void ph_body_create_circle(void) {

	int mass = getparm();
	int diameter = getparm();
	int pid = getparm();

	// Add procbody to linked list
	struct procbody *newb = (struct procbody*)div_malloc(sizeof(struct procbody));
	newb->next = bodies;
	newb->prev = NULL;

	// The moment of inertia is like mass for rotation
	// Use the cpMomentFor*() functions to help you approximate it.
	cpFloat radius = ((float)diameter)/2;//20*(proc(pid)->size*100)/10000;
	cpFloat moment = cpMomentForCircle(mass, 0, radius, cpvzero);

	// Setup procbody
	newb->body = cpSpaceAddBody(space, cpBodyNew(mass, moment));
	newb->procid = pid;

	cpBodySetPosition(newb->body, cpv( ((process *)&mem[pid])->x,((process *)&mem[pid])->y));

	newb->shape = cpSpaceAddShape(space, cpCircleShapeNew(newb->body, radius, cpvzero));
	newb->shape->e = 0.75;

	cpShapeSetFriction(newb->shape, 0.7);

    // link it in
	if(bodies) {
		bodies->prev = newb;
    }
    bodies = newb;

	retval(0);
}

void ph_body_create_box(void) {

	int friction = getparm();
	int elasticity = getparm();
	int moment = getparm();
	int mass = getparm();
	cpFloat height = getparm();
	cpFloat width = getparm();
	int pid = getparm();

	// Add procbody to linked list
	struct procbody *newb = (struct procbody*)div_malloc(sizeof(struct procbody));
	newb->next = bodies;
	newb->prev = NULL;

	// The moment of inertia is like mass for rotation
	// Use the cpMomentFor*() functions to help you approximate it.
	cpFloat radius = 32;//((float)diameter)/2;//20*(proc(pid)->size*100)/10000;
	//cpFloat moment = INFINITY;

	// Setup procbody
	newb->body = cpBodyNew(mass, moment<(2<<31) ? moment : INFINITY);
	newb->procid = pid;

//	cpSegmentShapeNew(newb->body, cpv(width,height), cpv(0,height), radius);
//	cpSegmentShapeNew(newb->body, cpv(width,height), cpv(width,0), radius);
//	cpSegmentShapeNew(newb->body, cpv(width,height), cpv(0,height), radius);
//	cpSegmentShapeNew(newb->body, cpv(width,height), cpv(width,0), radius);
	printf("HELLO %i\n", __LINE__); fflush(stdout);

	newb->shape = cpSpaceAddShape(space, cpCircleShapeNew(newb->body, radius, cpv(0,-radius)));
	cpSpaceAddBody(space, newb->body);
	cpBodySetPosition(newb->body, cpv( ((process *)&mem[pid])->x,((process *)&mem[pid])->y));

//	cpShape* s = cpBoxShapeNew(newb->body, width, height, radius);
//	printf("HELLO %i\n", __LINE__); fflush(stdout);
//	newb->shape = cpSpaceAddShape(space, s);
//	newb->shape = cpSpaceAddShape(space, cpCircleShapeNew(newb->body, radius, cpvzero));
	newb->shape->e = elasticity/100;

	cpShapeSetFriction(newb->shape, friction/100);

    // link it in
	if(bodies) {
		bodies->prev = newb;
    }
    bodies = newb;

	retval(0);
}
void phys_init(void){
	// cpVect is a 2D vector and cpv() is a shortcut for initializing them.
	
	int a=0;
	for(a=0;a<WALL_MAX;a++) {
		walls[a]=NULL;
	}
	
	gravity = cpv(0, 1000);
//	bodies = (struct procbody *)div_malloc(sizeof(struct procbody));
//	bodies->next = NULL;
//	bodies->prev = NULL;
//	bodies->procid=0;
//	bodies->shape=NULL;
//	bodies->body=NULL;
	
	
	
	// Create an empty space.
	space = cpSpaceNew();
	
	cpSpaceSetGravity(space, gravity);
	
	// Add a static line segment shape for the ground.
	// We'll make it slightly tilted so the ball will roll off.
	// We attach it to space->staticBody to tell Chipmunk it shouldn't be movable.


/*	walls[0] = cpSegmentShapeNew(space->staticBody, cpv(-60,height-220), cpv(wide/2,height-120), 10);
	walls[1] = cpSegmentShapeNew(space->staticBody, cpv(50,height+20), cpv(wide+60,height-40), 10);
	walls[2] = cpSegmentShapeNew(space->staticBody, cpv(200,height-240), cpv(wide+60,height-340), 10);
//	walls[2] = cpSegmentShapeNew(space->staticBody, cpv(-60,height-420), cpv(wide-150,height-320), 5);
	
	walls[0]->e=0.9;
	walls[1]->e=0.9;
	walls[2]->e=0.9;
	
	cpShapeSetFriction(walls[0], 1);
	cpSpaceAddShape(space, walls[0]);
	cpShapeSetFriction(walls[1], 1);
	cpSpaceAddShape(space, walls[1]);
	cpShapeSetFriction(walls[2], 1);
	cpSpaceAddShape(space, walls[2]);
*/

	printf("iloc_len: %d id_start: %d\n",iloc_len,imem);
	
	// Now let's make a ball that falls onto the line and rolls off.
	// First we need to make a cpBody to hold the physical properties of the object.
	// These include the mass, position, velocity, angle, etc. of the object.
	// Then we attach collision shapes to the cpBody to give it a size and shape.

	// The cpSpaceAdd*() functions return the thing that you are adding.
	// It's convenient to create and add an object in one line.
	// Now we create the collision shape for the ball.
	// You can create multiple collision shapes that point to the same body.
	// They will all be attached to the body and move around to follow it.
	
//	ballShape = cpSpaceAddShape(space, cpCircleShapeNew(ballBody, radius, cpvzero));
//	cpShapeSetFriction(ballShape, 0.7);
	
	// Now that it's all set up, we simulate all the objects in the space by
	// stepping forward through time in small increments called steps.
	// It is *highly* recommended to use a fixed size time step.
	//cpSpaceStep(space, timeStep);
	/*
	 * 
	
	for(cpFloat time = 0; time < 2; time += timeStep){
		cpVect pos = cpBodyGetPos(ballBody);
		cpVect vel = cpBodyGetVel(ballBody);
		cpFloat ang = cpBodyGetAngle(ballBody);
		double ang2;
		ang2=to_degrees((double)ang);

		if(time>=2-timeStep)
			printf(
				"Time is %5.2f. ballBody is at (%5.2f, %5.2f, %5.2f (%5.2f)). It's velocity is (%5.2f, %5.2f)\n",
				time, pos.x, pos.y, ang, ang2, vel.x, vel.y
			);
		
		
		
		cpSpaceStep(space, timeStep);
	}
*/
//printf("BallBody: %x\n",(unsigned int)ballBody);
    init = 1;
    retval(0);
}
struct procbody * findbody(int id) {
	struct procbody *f = bodies;

    for(;f; f = f->next) {
        if(f->procid == id) {
            return f;
        }
    }

	return NULL;
}

void kill_id(struct procbody *f) {
	if(f==NULL)
		return;
		
	struct procbody *p = f->prev;
	struct procbody *n = f->next;

// redo stack
	if(p!=NULL) {
		p->next=f->next;
	}
	
	if(n!=NULL) {
		n->prev = f->prev;
	}

	cpSpaceRemoveShape(space, f->shape);
	cpSpaceRemoveBody(space, f->body);
	cpShapeFree(f->shape);
	cpBodyFree(f->body);

//	printf("process dead %d\n",id_offset);
	
	free(f);
	
	return ;

}


void phys_loop(void) {

	struct procbody *f = bodies;
	
//	while(f!=NULL) {
//		if(f->procid>0)
//			if(proc(f->procid)->reserved.status==0)
//				kill_id(f);
//
//		f=f->next;
//
//	}
//    return;

//	if(!ballBody)
//		phys_init();
	
//		for(cpFloat time = 0; time < 2; time += timeStep){
	timeStep = 1/(float)(fps*1.0f);
	
//	printf("fps: %d\n",fps);
	

	cpSpaceStep(space, timeStep);
/*
	pos = cpBodyGetPos(ballBody);
	vel = cpBodyGetVel(ballBody);
	ang = cpBodyGetAngle(ballBody);
	
	ang2=to_degrees((double)ang);

//	if(time>=2-timeStep)
		printf(
			//"Time is %5.2f. "
			"ballBody is at (%5.2f, %5.2f, %5.2f (%5.2f)). It's velocity is (%5.2f, %5.2f)\n",
			//time, 
			pos.x, pos.y, ang, ang2, vel.x, vel.y
		);
	
	*/
	
	// check for dead processes
	
	
	

}





void phys_end(void) {	
	// Clean up our objects and exit!
	//cpShapeFree(ballShape);
	//cpBodyFree(ballBody);
	//cpShapeFree(walls[0]);
	//cpSpaceFree(space);
	
//	return 0;
}

void post_process(void) {

	if(!id_offset)
		return;

	struct procbody *f = findbody(id_offset);

	if(f==NULL)
		return;

	if(proc(id_offset)->reserved.status==0) {
		kill_id(f);
		return;
	}

	pos = cpBodyGetPosition(f->body);

	ang2 = to_degrees(cpBodyGetAngle(f->body));

//	vel = cpBodyGetVel(f->body);
//	ang2=to_degrees((double)ang);

//	cpCircleShapeSetRadius(f->shape, 20*(proc(id_offset)->size*100)/10000); 

	proc(id_offset)->x=pos.x;
	proc(id_offset)->y=pos.y;
	
//	printf("Proc data: id: %d radius: %d x0:%d y0:%d x1:%d y1:%d\n",id_offset, (proc(id_offset)->radius), (proc(id_offset)->reserved.x0),(proc(id_offset)->reserved.y0),(proc(id_offset)->reserved.x1),(proc(id_offset)->reserved.y1));
//	printf("Proc data: id: %d graph: %d x0:%d y0:%d x1:%d y1:%d\n",id_offset, (proc(id_offset)->graph), (proc(id_offset)->reserved.x0),(proc(id_offset)->reserved.y0),(proc(id_offset)->reserved.x1),(proc(id_offset)->reserved.y1));
	

	proc(id_offset)->angle=-ang2*1000;

}

void __export divlibrary(LIBRARY_PARAMS)
{

	COM_export("rum",rum,1);
	COM_export("phys_init",phys_init,0);
	
	COM_export("add_body",add_body,1);
	COM_export("phy_body_create_circle",ph_body_create_circle,3);
	COM_export("phy_body_create_box",ph_body_create_box,7);
//	COM_export("phy_body_move",ph_body_move,3);
//	COM_export("phy_body_force",ph_body_move,3);

	COM_export("add_fixed_body",add_fixed_body,5); 
	COM_export("remove_fixed_body",remove_fixed_body,1);
	
//	COM_export("Pixelate_Background",Pixelate_Background,1);

}

void process_fpg(char *fpg, int32_t len) {
	printf("Processing fpg: %d\n",len);
	return;
	
}
void process_map(char *map, int32_t len) {
	printf("Processing map: %d\n",len);
	return;
}

void post_process_buffer(void) {
	if(!init)
        phys_init();
	phys_loop();
}

void __export divmain(COMMON_PARAMS)
{
    AutoLoad();
	GLOBAL_IMPORT();
	DIV_export("post_process_buffer",post_process_buffer);
//	DIV_export("background_to_buffer",background_to_buffer);
	DIV_export("process_fpg",process_fpg);
	DIV_export("process_map",process_map);
	
	DIV_export("post_process",post_process);
//	phys_init();
	
}

void __export divend(COMMON_PARAMS) { }