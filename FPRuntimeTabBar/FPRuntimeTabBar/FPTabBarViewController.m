//
//  FPTabBarViewController.m
//  FPRuntimeTabBar
//
//  Created by polycom on 2017/6/19.
//  Copyright © 2017年 com.polycom. All rights reserved.
//

#import "FPTabBarViewController.h"
#import "ViewController.h"

@interface FPTabBarViewController ()

@end

@implementation FPTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNavigationController];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configNavigationController {
    NSArray *imageArray = @[@"home", @"category", @"center", @"cart", @"mine"];
    NSArray *titleArray = @[@"首页", @"分类", @"", @"购物车", @"我"];
    
    for (int i = 0; i < imageArray.count; i++) {
        ViewController *vc = [[ViewController alloc] init];
        vc.tabBarItem.image = [[UIImage imageNamed:imageArray[2]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        vc.tabBarItem.selectedImage = [[UIImage imageNamed:[imageArray[2] stringByAppendingString:@"_selected"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        vc.title = titleArray[i];
        
        if(i == 3) {
            vc.tabBarItem.badgeValue = @"99";
        }
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        [self addChildViewController:navController];
    }
}

@end
