//
//  ObjectiveScriptTests.m
//  ObjectiveScriptTests
//
//  Created by Kabir Oberai on 16/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "ObjectiveScript.h"
#import "JXJSInterop.h"
#import "JXType.h"

JSContext *JXCreateContext(void);

@interface ObjectiveScriptTests : XCTestCase

@end

@implementation ObjectiveScriptTests {
	JSContext *_ctx;

    struct {
        id __unsafe_unretained *bar;
        void (*foo[5])(void);
        SEL abc;
        Class cls;
        int baz;
        NSString * __unsafe_unretained str;
        id<NSCopying, NSCoding> __unsafe_unretained proto;
        NSDictionary<NSCopying, NSCoding> * __unsafe_unretained another;
    } type;
}

- (void)randomMethod:(const int)foo {

}

- (void)setUp {
    [super setUp];
	_ctx = JXCreateContext();
}

- (void)tearDown {
	_ctx = nil;
    [super tearDown];
}

- (void)testCtxExists {
	XCTAssertNotNil(_ctx, @"ctx is nil");
}

- (void)testNativePerformance {
	[self measureBlock:^{
		for (int i = 0; i < 1000000; i++) strcmp("hello", "henlo");
	}];
}

- (void)testJSPerformance {
	JSContext *ctx = JXCreateContext();
	[ctx evaluateScript:@"loadFunc('strcmp', 'i**', true);"];
	
	[self measureBlock:^{
		[ctx evaluateScript:@"for (var i = 0; i < 10000; i++) strcmp('hello', 'henlo');"];
	}];
}

- (void)testHookPerformance {
	JSContext *ctx = JXCreateContext();
	[self measureBlock:^{
		for (int i = 0; i < 200; i++) {
			[ctx evaluateScript:@"hookClass('UIViewController', {}, { 'v@:B-viewDidAppear:':function(){} })"];
		}
	}];
}

const char *_protocol_getMethodTypeEncoding(Protocol *, SEL, BOOL isRequiredMethod, BOOL isInstanceMethod);

- (void)testTypes {
//    const char *enc = "{EventBase=\"_vptr$TimeoutManager\"^^?\"_vptr$DrivableExecutor\"^^?\"pendingCobTimeouts_\"{list<folly::EventBase::CobTimeout, boost::intrusive::member_hook<folly::EventBase::CobTimeout, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::CobTimeout::hook>, boost::intrusive::constant_time_size<false>, void, void>=\"data_\"{data_t=\"root_plus_size_\"{root_plus_size=\"m_header\"{default_header_holder<boost::intrusive::list_node_traits<void *> >=\"next_\"^{list_node<void *>}\"prev_\"^{list_node<void *>}}}}}\"loopCallbacks_\"{list<folly::EventBase::LoopCallback, boost::intrusive::member_hook<folly::EventBase::LoopCallback, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::LoopCallback::hook_>, boost::intrusive::constant_time_size<false>, void, void>=\"data_\"{data_t=\"root_plus_size_\"{root_plus_size=\"m_header\"{default_header_holder<boost::intrusive::list_node_traits<void *> >=\"next_\"^{list_node<void *>}\"prev_\"^{list_node<void *>}}}}}\"runBeforeLoopCallbacks_\"{list<folly::EventBase::LoopCallback, boost::intrusive::member_hook<folly::EventBase::LoopCallback, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::LoopCallback::hook_>, boost::intrusive::constant_time_size<false>, void, void>=\"data_\"{data_t=\"root_plus_size_\"{root_plus_size=\"m_header\"{default_header_holder<boost::intrusive::list_node_traits<void *> >=\"next_\"^{list_node<void *>}\"prev_\"^{list_node<void *>}}}}}\"onDestructionCallbacks_\"{list<folly::EventBase::LoopCallback, boost::intrusive::member_hook<folly::EventBase::LoopCallback, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::LoopCallback::hook_>, boost::intrusive::constant_time_size<false>, void, void>=\"data_\"{data_t=\"root_plus_size_\"{root_plus_size=\"m_header\"{default_header_holder<boost::intrusive::list_node_traits<void *> >=\"next_\"^{list_node<void *>}\"prev_\"^{list_node<void *>}}}}}\"runAfterDrainCallbacks_\"{list<folly::EventBase::LoopCallback, boost::intrusive::member_hook<folly::EventBase::LoopCallback, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::LoopCallback::hook_>, boost::intrusive::constant_time_size<false>, void, void>=\"data_\"{data_t=\"root_plus_size_\"{root_plus_size=\"m_header\"{default_header_holder<boost::intrusive::list_node_traits<void *> >=\"next_\"^{list_node<void *>}\"prev_\"^{list_node<void *>}}}}}\"runOnceCallbacks_\"^{list<folly::EventBase::LoopCallback, boost::intrusive::member_hook<folly::EventBase::LoopCallback, boost::intrusive::list_member_hook<boost::intrusive::link_mode<boost::intrusive::link_mode_type::auto_unlink>, void, void>, &folly::EventBase::LoopCallback::hook_>, boost::intrusive::constant_time_size<false>, void, void>}\"stop_\"{atomic<bool>=\"__a_\"AB}\"loopThread_\"{atomic<_opaque_pthread_t *>=\"__a_\"A^{_opaque_pthread_t}}\"evb_\"^{event_base}\"queue_\"{unique_ptr<folly::NotificationQueue<std::__1::function<void ()> >, std::__1::default_delete<folly::NotificationQueue<std::__1::function<void ()> > > >=\"__ptr_\"{__compressed_pair<folly::NotificationQueue<std::__1::function<void ()> > *, std::__1::default_delete<folly::NotificationQueue<std::__1::function<void ()> > > >=\"__first_\"^{NotificationQueue<std::__1::function<void ()> >}}}\"fnRunner_\"{unique_ptr<folly::EventBase::FunctionRunner, std::__1::default_delete<folly::EventBase::FunctionRunner> >=\"__ptr_\"{__compressed_pair<folly::EventBase::FunctionRunner *, std::__1::default_delete<folly::EventBase::FunctionRunner> >=\"__first_\"^{FunctionRunner}}}\"maxLatency_\"q\"avgLoopTime_\"{SmoothLoopTime=\"expCoeff_\"d\"value_\"d\"oldBusyLeftover_\"q}\"maxLatencyLoopTime_\"{SmoothLoopTime=\"expCoeff_\"d\"value_\"d\"oldBusyLeftover_\"q}\"maxLatencyCob_\"{function<void ()>=\"__buf_\"{type=\"__lx\"[24C]}\"__f_\"^{__base<void ()>}}\"enableTimeMeasurement_\"B\"nextLoopCnt_\"Q\"latestLoopCnt_\"Q\"startWork_\"Q\"observer_\"{shared_ptr<folly::EventBaseObserver>=\"__ptr_\"^{EventBaseObserver}\"__cntrl_\"^{__shared_weak_count}}\"observerSampleCount_\"I\"executionObserver_\"^{ExecutionObserver}\"name_\"{basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >=\"__r_\"{__compressed_pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<char> >=\"__first_\"{__rep=\"\"(?=\"__l\"{__long=\"__data_\"*\"__size_\"Q\"__cap_\"Q}\"__s\"{__short=\"__data_\"[23c]\"\"{?=\"__size_\"C}}\"__r\"{__raw=\"__words\"[3Q]})}}}\"onDestructionCallbacksMutex_\"{mutex=\"__m_\"{_opaque_pthread_mutex_t=\"__sig\"q\"__opaque\"[56c]}}\"runAfterDrainCallbacksMutex_\"{mutex=\"__m_\"{_opaque_pthread_mutex_t=\"__sig\"q\"__opaque\"[56c]}}\"localStorageMutex_\"{mutex=\"__m_\"{_opaque_pthread_mutex_t=\"__sig\"q\"__opaque\"[56c]}}\"localStorage_\"{unordered_map<unsigned long long, std::__1::shared_ptr<void>, std::__1::hash<unsigned long long>, std::__1::equal_to<unsigned long long>, std::__1::allocator<std::__1::pair<const unsigned long long, std::__1::shared_ptr<void> > > >=\"__table_\"{__hash_table<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, std::__1::__unordered_map_hasher<unsigned long long, std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, std::__1::hash<unsigned long long>, true>, std::__1::__unordered_map_equal<unsigned long long, std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, std::__1::equal_to<unsigned long long>, true>, std::__1::allocator<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> > > >=\"__bucket_list_\"{unique_ptr<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *[], std::__1::__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *> > >=\"__ptr_\"{__compressed_pair<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> **, std::__1::__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *> > >=\"__first_\"^^{__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *>}\"__second_\"{__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *> >=\"__data_\"{__compressed_pair<unsigned long, std::__1::allocator<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *> >=\"__first_\"Q}}}}\"__p1_\"{__compressed_pair<std::__1::__hash_node_base<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *>, std::__1::allocator<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> > >=\"__first_\"{__hash_node_base<std::__1::__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *> *>=\"__next_\"^{__hash_node<std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, void *>}}}\"__p2_\"{__compressed_pair<unsigned long, std::__1::__unordered_map_hasher<unsigned long long, std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, std::__1::hash<unsigned long long>, true> >=\"__first_\"Q}\"__p3_\"{__compressed_pair<float, std::__1::__unordered_map_equal<unsigned long long, std::__1::__hash_value_type<unsigned long long, std::__1::shared_ptr<void> >, std::__1::equal_to<unsigned long long>, true> >=\"__first_\"f}}}\"localStorageToDtor_\"{unordered_set<folly::detail::EventBaseLocalBaseBase *, std::__1::hash<folly::detail::EventBaseLocalBaseBase *>, std::__1::equal_to<folly::detail::EventBaseLocalBaseBase *>, std::__1::allocator<folly::detail::EventBaseLocalBaseBase *> >=\"__table_\"{__hash_table<folly::detail::EventBaseLocalBaseBase *, std::__1::hash<folly::detail::EventBaseLocalBaseBase *>, std::__1::equal_to<folly::detail::EventBaseLocalBaseBase *>, std::__1::allocator<folly::detail::EventBaseLocalBaseBase *> >=\"__bucket_list_\"{unique_ptr<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *[], std::__1::__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *> > >=\"__ptr_\"{__compressed_pair<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> **, std::__1::__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *> > >=\"__first_\"^^{__hash_node<folly::detail::EventBaseLocalBaseBase *, void *>}\"__second_\"{__bucket_list_deallocator<std::__1::allocator<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *> >=\"__data_\"{__compressed_pair<unsigned long, std::__1::allocator<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *> >=\"__first_\"Q}}}}\"__p1_\"{__compressed_pair<std::__1::__hash_node_base<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *>, std::__1::allocator<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> > >=\"__first_\"{__hash_node_base<std::__1::__hash_node<folly::detail::EventBaseLocalBaseBase *, void *> *>=\"__next_\"^{__hash_node<folly::detail::EventBaseLocalBaseBase *, void *>}}}\"__p2_\"{__compressed_pair<unsigned long, std::__1::hash<folly::detail::EventBaseLocalBaseBase *> >=\"__first_\"Q}\"__p3_\"{__compressed_pair<float, std::__1::equal_to<folly::detail::EventBaseLocalBaseBase *> >=\"__first_\"f}}}}";
//    const char *enc = ivar_getTypeEncoding(class_getInstanceVariable([self class], "type"));
    // {foo="bar"@"NSString<NSCopying><NSCoding>""baz"i}
//    const char *enc = _protocol_getMethodTypeEncoding(@protocol(FooProtocol), @selector(testMethod:), YES, YES);
//    const char *enc = "{CGRect={CGPoint=@\"NSString\"[15d]}{CGSize=d^d}}";
//    const char *enc = "@\"NSString\"";
    const char *enc = "{Foo=\"bar\"@\"baz\"i}";
//    const char *enc = "{CGRect=\"origin\"{CGPoint=\"x\"d\"y\"d}\"size\"{CGSize=\"width\"d\"height\"d}}";
    JXType *parsed = JXTypeForEncoding(enc);
    // struct { id *bar; void (*foo[5])(void); SEL abc; Class cls; int baz; NSString *str; id<NSCopying, NSCoding> proto; NSDictionary<NSCopying, NSCoding> *another; }
    NSLog(@"\n%@", parsed);
}

// TODO: Add more tests

@end
